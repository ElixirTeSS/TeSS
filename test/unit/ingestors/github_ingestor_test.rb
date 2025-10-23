# frozen_string_literal: true

require 'test_helper'

class GithubIngestorTest < ActiveSupport::TestCase # rubocop:disable Metrics/ClassLength
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @ingestor = Ingestors::GithubIngestor.new
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)
    mock_timezone # System time zone should not affect test result

    # Sitemap
    webmock('https://hsf-training.org/training-center/sitemap.txt', 'github/sitemap.txt')

    # Pages' html
    webmock('https://github.com/hsf-training/cpluspluscourse', 'github/mock.html')
    webmock('https://swcarpentry.github.io/python-novice-inflammation/', 'github/mock.html')
    webmock('https://hsf-training.github.io/hsf-training-scikit-hep-webpage/', 'github/mock.html')
    webmock('https://testwebsite.blabla', 'github/mock.html')

    # API
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse', 'github/api-github-com.json')
    webmock('https://api.github.com/repos/swcarpentry/python-novice-inflammation', 'github/api-github-io-01.json')
    webmock('https://api.github.com/repos/hsf-training/hsf-training-scikit-hep-webpage', 'github/api-github-io-02.json')

    # Contributors
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse/contributors', 'github/contributors.json')
    webmock('https://api.github.com/repos/swcarpentry/python-novice-inflammation/contributors', 'github/contributors.json')
    webmock('https://api.github.com/repos/hsf-training/hsf-training-scikit-hep-webpage/contributors', 'github/contributors.json')

    # Readme
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse/contents/README.md', 'github/readme.json')
    webmock('https://api.github.com/repos/swcarpentry/python-novice-inflammation/contents/README.md', 'github/readme.json')
    webmock('https://api.github.com/repos/hsf-training/hsf-training-scikit-hep-webpage/contents/README.md', 'github/readme.json')

    # Releases
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse/releases', 'github/releases.json')
    webmock('https://api.github.com/repos/swcarpentry/python-novice-inflammation/releases', 'github/releases.json')
    webmock('https://api.github.com/repos/hsf-training/hsf-training-scikit-hep-webpage/releases', 'github/releases.json')

    # HTML
    html = File.read(Rails.root.join('test/fixtures/files/ingestion/github/mock.html'))
    @doc = Nokogiri::HTML(html)

    # config cache working here
    @old_cache_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    reset_timezone
    Rails.cache = @old_cache_store
  end
  test 'valid https github.com URL' do
    url = 'https://github.com/hsf-training/cpluspluscourse'
    expected = 'https://api.github.com/repos/hsf-training/cpluspluscourse'
    assert_equal expected, @ingestor.send(:to_github_api, url)
  end

  test 'valid http github.com URL' do
    url = 'http://github.com/hsf-training/cpluspluscourse'
    expected = 'https://api.github.com/repos/hsf-training/cpluspluscourse'
    assert_equal expected, @ingestor.send(:to_github_api, url)
  end

  test 'invalid github.com URL missing reponame' do
    url = 'https://github.com/hsf-training/'
    assert_nil @ingestor.send(:to_github_api, url)
  end

  test 'invalid github.com URL too deep path' do
    url = 'https://github.com/hsf-training/cpluspluscourse/extra'
    assert_nil @ingestor.send(:to_github_api, url)
  end

  test 'valid github.io URL' do
    url = 'https://hsf-training.github.io/cpluspluscourse/'
    expected = 'https://api.github.com/repos/hsf-training/cpluspluscourse'
    assert_equal expected, @ingestor.send(:to_github_api, url)
  end

  test 'invalid github.io with multiple subdomains' do
    url = 'https://bad.url.github.io/repo'
    assert_nil @ingestor.send(:to_github_api, url)
  end

  test 'invalid github.io without reponame' do
    url = 'https://hsf-training.github.io/'
    assert_nil @ingestor.send(:to_github_api, url)
  end

  test 'invalid non-github host' do
    url = 'https://gitlab.com/hsf-training/cpluspluscourse'
    assert_nil @ingestor.send(:to_github_api, url)
  end

  test 'should read sitemap.txt composed of github.com and github.io but avoid keeping the non-github URLs' do
    # Read sitemap
    @ingestor.read('https://hsf-training.org/training-center/sitemap.txt')

    # There should be 3 github.{com|io} urls among 4 urls
    assert_equal 3, @ingestor.materials.count
    messages = @ingestor.messages.join("\n")
    assert_includes messages, 'Parsing .txt sitemap:'
    assert_includes messages, "\n - 4 URLs found"

    assert_difference('Material.count', 3) do
      @ingestor.write(@user, @content_provider)
    end

    # It thus adds 3 materials
    assert_equal 3, @ingestor.stats[:materials][:added]
    assert_equal 0, @ingestor.stats[:materials][:updated]
    assert_equal 0, @ingestor.stats[:materials][:rejected]
  end

  test 'open uri safety' do
    ingestor = Ingestors::GithubIngestor.new
    dir = Rails.root.join('tmp')
    file = dir.join("test#{SecureRandom.urlsafe_base64(20)}").to_s
    refute File.exist?(file)
    begin
      ingestor.open_url("| touch #{file}")
    rescue StandardError
    end
    `ls #{dir}` # This is needed or the `exist?` check below seems to return a stale result
    refute File.exist?(file)
  end

  test 'should read github.com source' do
    @ingestor.read('https://github.com/hsf-training/cpluspluscourse')
    @ingestor.write(@user, @content_provider)

    sample = @ingestor.materials.detect { |e| e.title == 'Cpluspluscourse' }
    assert sample.persisted?

    assert_equal sample.url, 'https://github.com/hsf-training/cpluspluscourse'
    assert_equal sample.description, 'C++ Course Taught at CERN' # taken from api.description
    assert_equal sample.keywords, %w[those are keywords]
    assert_equal sample.licence, 'Apache-2.0'
    assert_equal sample.status, 'Archived'
    assert_equal sample.doi, 'https://doi.org/10.5281/zenodo.4670321'
    assert_equal sample.version, '1.0.0'
    assert_equal sample.date_created, Date.new(2025, 9, 29)
    assert_equal sample.date_published, Date.new(2025, 9, 28)
    assert_equal sample.date_modified, Date.new(2025, 9, 30)
    assert_equal sample.contributors, %w[jane doe]
    assert_equal sample.resource_type, ['Github Repository'] # when no gh page
    assert_equal sample.prerequisites, '1. Be kind'
  end

  test 'should read github.io source' do
    @ingestor.read('https://swcarpentry.github.io/python-novice-inflammation/')
    @ingestor.write(@user, @content_provider)

    sample = @ingestor.materials.detect { |e| e.title == 'Python Novice Inflammation' }
    assert sample.persisted?

    assert_equal sample.url, 'https://swcarpentry.github.io/python-novice-inflammation/'
    assert_equal sample.description, "This is the second p tag of the page fetched because it has more than 50 chars\n(...) [Read more...](https://swcarpentry.github.io/python-novice-inflammation/)"
    assert_equal sample.status, 'Active' # changed to false
    assert_equal sample.resource_type, ['Github Page'] # when gh page
  end

  test 'should cache github repo metadata' do
    cache = 'github_ingestor_api.github.com_repos_hsf-training_cpluspluscourse'

    @ingestor.read('https://github.com/hsf-training/cpluspluscourse')

    # Assert cache now exists
    assert Rails.cache.exist?(cache), "Expected Rails cache #{cache} to exist"

    # Assert cache value
    cache_read = Rails.cache.read(cache)
    assert_equal cache_read['name'], 'cpluspluscourse'

    # Assert material value matching the cache value
    sample = @ingestor.materials.detect { |e| e.title == 'Cpluspluscourse' }
    assert_equal sample.title, cache_read['name'].titleize
  end

  test 'should write cache of github repo metadata when first read and read cache only when second read' do
    cache = 'github_ingestor_api.github.com_repos_hsf-training_cpluspluscourse'
    Rails.cache.delete(cache)
    @ingestor.read('https://github.com/hsf-training/cpluspluscourse')

    # Set current cache `name` to something else to assure ourselves we keep this one
    cache_modified = Rails.cache.read(cache)
    cache_modified['name'] = 'manualchange'
    Rails.cache.write(cache, cache_modified)
    assert_equal cache_modified['name'], 'manualchange'

    # Reading a second time (within a specific time period) should GET cache and not SET cache
    @ingestor.read('https://github.com/hsf-training/cpluspluscourse')
    cache_second = Rails.cache.read(cache)

    # Assert cache STILL exists
    assert Rails.cache.exist?(cache), "Expected Rails cache #{cache} to exist"

    # Assert `name` cache is still the changed one in the second-read cache
    assert_equal cache_second['name'], 'manualchange'

    # Material value is independent from this manual cache modification
    sample = @ingestor.materials.detect { |e| e.title == 'Cpluspluscourse' }
    assert_equal sample.title, 'Cpluspluscourse'
  end

  test 'should set cache and test cache and material before ttl' do
    cache = 'github_ingestor_api.github.com_repos_hsf-training_cpluspluscourse'
    Rails.cache.delete(cache)
    @ingestor.read('https://github.com/hsf-training/cpluspluscourse')
    sample = @ingestor.materials.detect { |e| e.title == 'Cpluspluscourse' }
    assert_equal sample.title, 'Cpluspluscourse'
    expires_at7 = Rails.cache.send(:read_entry, cache)&.expires_at
    assert_equal (expires_at7 - Time.now.to_f).round, 7 * 24 * 60 * 60 # time to live is 7 days by default

    # Let's change material and cache to be sure it is this one we are using
    sample.title = 'Manualchange'
    cache_modified = Rails.cache.read(cache)
    cache_modified['name'] = 'manualchange'
    Rails.cache.write(cache, cache_modified, expires_in: 3.seconds) # set new cache ttl to 3 seconds
    assert_equal cache_modified['name'], 'manualchange'

    # Before ttl, content is changed, cache is not changed nor material
    # Assert it is really 3 sec
    expires_at3 = Rails.cache.send(:read_entry, cache)&.expires_at
    assert_equal (expires_at3 - Time.now.to_f).round, 3
    sleep(1)
    # Assert ttl is now 2 sec
    expires_at2 = Rails.cache.send(:read_entry, cache)&.expires_at
    assert_equal (expires_at2 - Time.now.to_f).round, 2

    # After 1 second, even if the content changes, the previous material and cache are still used
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse', 'github/api-modified.json')
    @ingestor.read('https://github.com/hsf-training/cpluspluscourse')
    sample_second = @ingestor.materials.detect { |e| e.title == 'Manualchange' }
    cache_after = Rails.cache.read(cache)
    # manualchange instead of bigchange
    assert_equal sample_second.title, 'Manualchange'
    assert_equal cache_after['name'], 'manualchange'
    # Assert ttl is still 2 sec
    expires_at2again = Rails.cache.send(:read_entry, cache)&.expires_at
    assert_equal (expires_at2again - Time.now.to_f).round, 2
  end

  test 'should set cache then test cache and material after ttl' do
    cache = 'github_ingestor_api.github.com_repos_hsf-training_cpluspluscourse'
    Rails.cache.delete(cache)
    @ingestor.read('https://github.com/hsf-training/cpluspluscourse')
    sample = @ingestor.materials.detect { |e| e.title == 'Cpluspluscourse' }
    sample.title = 'Manualchange'
    cache_modified = Rails.cache.read(cache)
    cache_modified['name'] = 'manualchange'
    Rails.cache.write(cache, cache_modified, expires_in: 2.seconds)
    assert_equal Rails.cache.read(cache)['name'], 'manualchange'

    # After ttl, if content – and thus cache – are changed, then the material should be partially changed
    expires_at2 = Rails.cache.send(:read_entry, cache)&.expires_at
    assert_equal (expires_at2 - Time.now.to_f).round, 2
    # After 2 seconds, if the content changes, the cache expires and we fetch the newest content
    sleep(2)
    # We do not have cache anymore
    assert_nil Rails.cache.read(cache)
    # But the material is still here with the manual modification
    sample_after_ttl = @ingestor.materials.detect { |e| e.title == cache_modified['name'].titleize }
    assert_equal sample_after_ttl.title, cache_modified['name'].titleize

    # Now if content has changed and we read it
    webmock('https://api.github.com/repos/hsf-training/cpluspluscourse', 'github/api-modified.json')
    @ingestor.read('https://github.com/hsf-training/cpluspluscourse')

    # We should have our cache changed as well as the ENTIRE material
    cache_after_ttl = Rails.cache.read(cache)
    assert_equal cache_after_ttl['name'], 'bigchange'
    sample_after_ttl_and_change = @ingestor.materials.detect { |e| e.title == cache_after_ttl['name'].titleize }
    # The material title has changed – because api-modified.json only have 'name'
    assert_equal sample_after_ttl_and_change.title, cache_after_ttl['name'].titleize
    # The material keywords is the new one
    assert_equal sample_after_ttl_and_change.keywords, %w[those are NOT]
    # The material description is the new one: nil
    assert_nil sample_after_ttl_and_change.description
  end

  test 'std errors when exception is raised' do
    @ingestor.stub(:get_sources, ->(_url) { raise StandardError, 'test failure' }) do
      @ingestor.send(:read, 'https://github.com/example')
    end
    assert_includes @ingestor.instance_variable_get(:@messages).last,
                    'Ingestors::GithubIngestor read failed, test failure'

    @ingestor.stub(:open_url, ->(_url) { raise StandardError, 'test failure' }) do
      @ingestor.send(:get_or_set_cache, 'key', 'https://github.com/example')
    end
    assert_includes @ingestor.instance_variable_get(:@messages).last,
                    'Ingestors::GithubIngestor get_or_set_cache failed for https://github.com/example, test failure'

    @ingestor.stub(:get_or_set_cache, ->(_key, _url) { raise StandardError, 'test failure' }) do
      @ingestor.send(:fetch_doi, 'full_name')
    end
    assert_includes @ingestor.instance_variable_get(:@messages).last,
                    'Ingestors::GithubIngestor fetch_doi failed for https://api.github.com/repos/full_name/contents/README.md, test failure'

    @ingestor.stub(:get_or_set_cache, ->(_key, _url) { raise StandardError, 'test failure' }) do
      @ingestor.send(:fetch_latest_release, 'full_name')
    end
    assert_includes @ingestor.instance_variable_get(:@messages).last,
                    'Ingestors::GithubIngestor fetch_latest_release failed for https://api.github.com/repos/full_name/releases, test failure'

    @ingestor.stub(:get_or_set_cache, ->(_key, _url) { raise StandardError, 'test failure' }) do
      @ingestor.send(:fetch_contributors, 'my.url', 'full_name')
    end
    assert_includes @ingestor.instance_variable_get(:@messages).last,
                    'Ingestors::GithubIngestor fetch_contributors failed for my.url, test failure'
  end

  test 'prereq_node? returns true when id includes prereq' do
    node = Nokogiri::XML::Node.new('div', @doc)
    node['id'] = 'prerequisites'
    assert @ingestor.send(:prereq_node?, node)
  end

  test 'prereq_node? returns true when class includes prereq' do
    node = Nokogiri::XML::Node.new('div', @doc)
    node['class'] = 'has_prereq_section'
    assert @ingestor.send(:prereq_node?, node)
  end

  test 'prereq_node? returns false for unrelated id/class' do
    node = Nokogiri::XML::Node.new('div', @doc)
    node['id'] = 'requirements'
    refute @ingestor.send(:prereq_node?, node)
  end

  test 'extract_following_paragraphs finds immediate sibling paragraphs' do
    doc = Nokogiri::HTML(<<~HTML)
      <div id="prereq"></div>
      <p>First paragraph</p>
      <ul><li>List item</li></ul>
      <h2>Stop here</h2>
    HTML

    node = doc.at_xpath('//*[@id="prereq"]')
    paragraphs = []
    @ingestor.send(:extract_following_paragraphs, node, paragraphs)

    assert_equal 2, paragraphs.size
    assert_equal %w[p ul], paragraphs.map(&:name)
  end

  test 'extract_nested_paragraphs finds paragraphs inside the node' do
    doc = Nokogiri::HTML(<<~HTML)
      <div id="prereq">
        <p>Nested paragraph</p>
        <ul><li>Nested list</li></ul>
      </div>
    HTML

    node = doc.at_xpath('//*[@id="prereq"]')
    paragraphs = []
    @ingestor.send(:extract_nested_paragraphs, node, paragraphs)

    assert_equal 2, paragraphs.size
    assert_equal %w[p ul], paragraphs.map(&:name)
  end

  test 'fetch_prerequisites_from_id_or_class collects prerequisites correctly' do
    doc = Nokogiri::HTML(<<~HTML)
      <div id="prereq"></div>
      <p>Be kind</p>
      <p>Have Ruby installed</p>
    HTML

    paragraphs = []
    result = @ingestor.send(:fetch_prerequisites_from_id_or_class, doc, paragraphs)

    assert_equal 2, result.size
    assert_equal 'Be kind', result.first.text
  end

  private

  def webmock(url, filename)
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
    WebMock.stub_request(:get, url).to_return(status: 200, headers: {}, body: file.read)
  end
end