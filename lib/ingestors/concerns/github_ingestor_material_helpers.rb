# frozen_string_literal: true

module Ingestors
  module Concerns
    # All methods for the Github Ingestor Class
    # This involves, the caching, the change from github.com to api.github.com
    module GithubIngestorMaterialHelpers
      private

      def resolve_url(repo_data)
        homepage_nil_or_empty = repo_data['homepage'].nil? || repo_data['homepage'].empty?
        url = homepage_nil_or_empty ? repo_data['html_url'] : get_redirected_url(repo_data['homepage'])
        [url, homepage_nil_or_empty]
      end

      def fetch_homepage_doc(url)
        response = HTTParty.get(url, follow_redirects: true, headers: { 'User-Agent' => config[:user_agent] })
        Nokogiri::HTML(response.body)
      end

      # DEFINITION – Opens the GitHub homepage, fetches the 3 first >25 char <p> tags'text
      # and joins them with a 'Read more...' link at the end of the description
      # Some of the first <p> tags were not descriptive, thus skipping them
      def fetch_definition(doc, url)
        desc = ''
        round = 3
        doc.css('p').each do |p|
          p_txt = p&.text&.strip&.gsub(/\s+/, ' ')
          next if (p_txt.length < 25) || round.zero?

          desc = "#{desc}\n#{p_txt}"
          round -= 1
        end
        "#{desc}\n(...) [Read more...](#{url})"
      end

      # LICENCE – Get proper licence
      # the licence must match the format of config/dictionaries/licences.yml
      def fetch_licence(licence)
        return 'notspecified' if licence.nil? || licence == 'null'
        return 'other-at' if licence['key'] == 'other'

        licence['spdx_id']
      end

      # DOI – Fetches DOI from various sources in a repo
      # I chose to only read the `README.md` as it seems to have the DOI badge almost everytime.
      # Whereas enabling the fetching of CITATION.cff or CITATION.md would result in increasing
      # the number of api request.
      def fetch_doi(full_name)
        fetch_doi_from_file(full_name, 'README.md')

        # doi = fetch_doi_from_file(full_name, 'CITATION.cff')
        # return doi if doi

        # doi = fetch_doi_from_file(full_name, 'CITATION.md')
        # return doi if doi
      rescue StandardError
        nil
      end

      # DOI – Fetches DOI from a specific file in repo (via GitHub API)
      def fetch_doi_from_file(full_name, filename)
        url = "#{GITHUB_API_BASE}/#{full_name}/contents/#{filename}"
        data = get_or_set_cache("doi_#{full_name.gsub('/', '_')}_#{filename.downcase}", url)
        return nil unless data && data['content']

        decoded = Base64.decode64(data['content'])
        doi_match = decoded.match(%r{doi.org/\s*([^\s,)]+)}i)
        doi_match ? "https://doi.org/#{doi_match[1]}" : nil
      rescue StandardError
        nil
      end

      # RELEASE – Opens releases API address and returns last release
      def fetch_latest_release(full_name)
        url = "#{GITHUB_API_BASE}/#{full_name}/releases"
        releases = get_or_set_cache("releases_#{full_name.gsub('/', '_')}", url)
        releases.is_a?(Array) && releases.first ? releases.first['tag_name'] : nil
      rescue StandardError
        nil
      end

      # CONTRIBUTORS – Opens contributors API address and returns list of contributors
      def fetch_contributors(contributors_url)
        contributors = get_or_set_cache("contributors_#{full_name.gsub('/', '_')}", contributors_url)
        contributors.map { |c| (c['login']) }
      rescue StandardError
        nil
      end

      # PREREQUISITES – From the homepage HTML, looks for <p> tags which are children of ...
      def fetch_prerequisites(doc)
        prereq_paragraphs = []

        # ... any heading tag (h1–h6) or span tag with text "prereq" (EN) or "prerreq" (ES)
        prereq_paragraphs = fetch_prerequisites_from_h(doc, prereq_paragraphs)

        # ... any tag with id containing "prereq" (EN) or "prerreq" (ES)
        prereq_paragraphs = fetch_prerequisites_from_id_or_class(doc, prereq_paragraphs) if prereq_paragraphs.empty?

        prereq_paragraphs&.join("\n")&.gsub(/\n\n+/, "\n")&.to_s&.strip
      end

      def fetch_prerequisites_from_h(doc, prereq_paragraphs)
        doc.xpath('//h1|//h2|//h3|//h4|//h5|//h6|//span').each do |h|
          next unless h.text =~ /prereq|prerreq/i # if prereq in text

          paragraph = h.xpath('following-sibling::*')
                       .take_while { |sib| %w[p ul ol].include?(sib.name) } # take either p, ul or ol
          prereq_paragraphs.concat(paragraph) if paragraph
        end
        prereq_paragraphs
      end

      def fetch_prerequisites_from_id_or_class(doc, prereq_paragraphs)
        doc.xpath('//*[@id]').each do |node|
          next unless prereq_node?(node)

          extract_following_paragraphs(node, prereq_paragraphs)
          extract_nested_paragraphs(node, prereq_paragraphs) if prereq_paragraphs.empty?
        end
        prereq_paragraphs
      end

      def prereq_node?(node)
        [node['id'], node['class']].compact.any? { |attr| attr =~ /prereq|prerreq/i }
      end

      def extract_following_paragraphs(node, prereq_paragraphs)
        paragraphs = node.xpath('following-sibling::*')
                         .take_while { |sib| %w[p ul ol].include?(sib.name) }
        prereq_paragraphs.concat(paragraphs) if paragraphs
      end

      def extract_nested_paragraphs(node, prereq_paragraphs)
        paragraphs = node.xpath('.//p | .//ul | .//ol')
        prereq_paragraphs.concat(paragraphs) if paragraphs.any?
      end
    end
  end
end
