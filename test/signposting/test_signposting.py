"""FAIR Signposting and RO-Crate integration tests against a running TeSS instance.

These use the `signposting` library (https://pypi.org/project/signposting/) as an independent client to check the
Link headers and HTML <link> elements of material and event pages, then follow them to the Detached RO-Crate.

Run against the test fixtures (see README.md), or any TeSS instance by setting TESS_URL:

    RAILS_ENV=test bin/rails db:fixtures:load
    RAILS_ENV=test bin/rails server -p 3000 &
    pip install -r test/signposting/requirements.txt
    TESS_URL=http://localhost:3000 pytest test/signposting
"""
import json
import os
import shutil
import subprocess
from urllib.parse import urljoin, urlsplit

import pytest
import requests
import signposting

TESS_URL = os.environ.get("TESS_URL", "http://localhost:3000").rstrip("/") + "/"
RO_CRATE_PROFILE = "https://w3id.org/ro/crate"
RO_CRATE_SPEC = "https://w3id.org/ro/crate/1.3"
JSON_LD = "application/ld+json"
SCHEMA_TYPES = {
    "materials": {"https://schema.org/LearningResource"},
    "events": {"https://schema.org/Event", "https://schema.org/Course"},
}
SAMPLE_SIZE = int(os.environ.get("TESS_SAMPLE_SIZE", "5"))


def resource_urls(kind, sample_size=SAMPLE_SIZE):
    """Page URLs of the first resources of a kind ("materials" or "events"), found through the JSON:API."""
    response = requests.get(urljoin(TESS_URL, f"{kind}.json_api"), params={"per_page": sample_size}, timeout=30)
    response.raise_for_status()
    return [urljoin(TESS_URL, item["links"]["self"]) for item in response.json()["data"]]


def resources(kind):
    try:
        urls = resource_urls(kind)
    except requests.RequestException as e:
        pytest.skip(f"TeSS not reachable at {TESS_URL}: {e}")
    if not urls:
        pytest.skip(f"No {kind} in TeSS at {TESS_URL}")
    return urls


def ro_crate_link(signposts):
    links = [d for d in signposts.describedBy if RO_CRATE_PROFILE in signposts_profiles(d)]
    assert len(links) == 1, f"Expected one RO-Crate describedby link, got {signposts.describedBy}"
    return links[0]


def signposts_profiles(signpost):
    return {str(p) for p in (signpost.profiles or [])}


def root_entity(crate):
    entities = {e["@id"]: e for e in crate["@graph"]}
    descriptor = entities["ro-crate-metadata.json"]
    return descriptor, entities[descriptor["about"]["@id"]], entities


@pytest.fixture(scope="module", params=["materials", "events"])
def kind(request):
    return request.param


@pytest.fixture(scope="module")
def page_urls(kind):
    return resources(kind)


def test_http_signposting(kind, page_urls):
    for url in page_urls:
        signposts = signposting.find_signposting_http(url)

        assert signposts.signposts, f"No signposting in Link header of {url}"
        link = ro_crate_link(signposts)
        assert str(link.type) == JSON_LD
        assert str(link.target) == url + "/ro-crate-metadata.json"

        bioschemas = [d for d in signposts.describedBy if str(d.target) == url + ".jsonld"]
        assert len(bioschemas) == 1
        assert any(p.startswith("https://bioschemas.org/profiles/") for p in signposts_profiles(bioschemas[0]))

        types = {str(t.target) for t in signposts.types}
        assert "https://schema.org/AboutPage" in types
        assert types & SCHEMA_TYPES[kind], f"Expected one of {SCHEMA_TYPES[kind]} in {types}"

        if signposts.citeAs:
            assert str(signposts.citeAs.target).startswith(("http://", "https://"))
            assert not str(signposts.citeAs.target).startswith(("http://doi.org/", "http://dx.doi.org/",
                                                                 "https://dx.doi.org/")), \
                "DOIs should be given as https://doi.org/ URLs"


def test_html_signposting_matches_http(page_urls):
    for url in page_urls:
        http = signposting.find_signposting_http(url)
        html = signposting.find_signposting_html(url)

        def links(s):
            return {(str(l.rel), str(l.target), str(l.type or ""), frozenset(signposts_profiles(l)))
                    for l in s.signposts}

        assert links(html) == links(http)


def test_follow_signposting_to_ro_crate(kind, page_urls):
    for url in page_urls:
        link = ro_crate_link(signposting.find_signposting_http(url))
        response = requests.get(str(link.target), timeout=30)
        response.raise_for_status()
        assert response.headers["Content-Type"].startswith(f'{JSON_LD}; profile="{RO_CRATE_PROFILE}"')

        crate = response.json()
        assert crate["@context"] == f"{RO_CRATE_SPEC}/context"
        descriptor, root, entities = root_entity(crate)
        assert descriptor["conformsTo"] == {"@id": RO_CRATE_SPEC}
        # Detached crate: the Root Data Entity is the page the signposting came from. Its host is TeSS's configured
        # base_url, which may differ from the host the tests reach the server through.
        assert urlsplit(root["@id"]).path == urlsplit(url).path
        assert "Dataset" in root["@type"]
        for prop in ("name", "description", "datePublished", "license"):
            assert root.get(prop), f"Root Data Entity of {url} has no {prop}"

        # Flattened: nested objects are only references, and every reference is described
        for entity in crate["@graph"]:
            for key, value in entity.items():
                if key.startswith("@"):
                    continue
                for v in value if isinstance(value, list) else [value]:
                    if isinstance(v, dict):
                        assert list(v) == ["@id"], f"Nested entity in {entity['@id']}.{key}: {v}"
                        if v["@id"].startswith("#"):
                            assert v["@id"] in entities, f"{v['@id']} is not described"


def test_content_negotiation(page_urls):
    for url in page_urls:
        response = requests.get(url, headers={"Accept": f'{JSON_LD}; profile="{RO_CRATE_PROFILE}"'}, timeout=30)
        response.raise_for_status()
        assert response.headers["Content-Type"].startswith(JSON_LD)
        descriptor, root, _ = root_entity(response.json())
        assert descriptor["conformsTo"] == {"@id": RO_CRATE_SPEC}

        # Without the profile, the Bioschemas JSON-LD is served as before
        bioschemas = requests.get(url, headers={"Accept": JSON_LD}, timeout=30).json()
        assert "@graph" not in bioschemas


def test_doi_rewritten_to_https_doi_org():
    """Materials whose DOI is given as http://doi.org/, http://dx.doi.org/, doi: or bare are cited as https://doi.org/."""
    response = requests.get(urljoin(TESS_URL, "materials.json_api"), params={"per_page": 100}, timeout=30)
    response.raise_for_status()
    with_doi = [m for m in response.json()["data"]
                if (m["attributes"].get("doi") or "").lower().startswith(("10.", "doi:", "http://doi.org/",
                                                                            "http://dx.doi.org/",
                                                                            "https://dx.doi.org/"))]
    if not with_doi:
        pytest.skip("No materials with a DOI to rewrite")

    for material in with_doi:
        url = urljoin(TESS_URL, material["links"]["self"])
        doi = material["attributes"]["doi"].strip()
        suffix = doi[doi.index("10."):]
        signposts = signposting.find_signposting_http(url)
        assert str(signposts.citeAs.target) == f"https://doi.org/{suffix}"

        crate = requests.get(str(ro_crate_link(signposts).target), timeout=30).json()
        _, root, _ = root_entity(crate)
        assert root["identifier"] == f"https://doi.org/{suffix}"


@pytest.mark.skipif(not shutil.which("rocrate-validator"), reason="rocrate-validator (roc-validator) not installed")
def test_ro_crate_validates(kind, page_urls, tmp_path):
    """No REQUIRED issues from rocrate-validator for the RO-Crate 1.3 profile."""
    for i, url in enumerate(page_urls):
        link = ro_crate_link(signposting.find_signposting_http(url))
        crate_dir = tmp_path / f"{kind}-{i}"
        crate_dir.mkdir()
        metadata = crate_dir / "ro-crate-metadata.json"
        metadata.write_text(requests.get(str(link.target), timeout=30).text)
        report = crate_dir / "report.json"

        subprocess.run(["rocrate-validator", "validate", "--profile-identifier", "ro-crate-1.3", "--no-paging",
                        "--metadata-only", "--requirement-severity", "REQUIRED", "--output-format", "json",
                        "--output-file", str(report), str(metadata)],
                       stdin=subprocess.DEVNULL, capture_output=True, timeout=600)

        result = json.loads(report.read_text())
        issues = [f"{i['violatingEntity']}: {i['message']}" for i in result["issues"]]
        assert result["passed"], f"{url} crate has issues:\n" + "\n".join(issues)
