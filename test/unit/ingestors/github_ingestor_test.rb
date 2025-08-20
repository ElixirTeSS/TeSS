require 'test_helper'

class GithubIngestorTest < ActiveSupport::TestCase
  setup do
  end

  teardown do
  end
  
  test 'should read sitemap of github.com and github.io and avoid test.com' do
  end

  test 'should read github.com source' do
  end  

  test 'should read github.io source' do
  end  

  test 'should set redis cache when first time with material' do
  end

  test 'should get redis cache when not first time with material' do
  end

  test 'should fetch github metadata' do
  end

  test 'should get definitions from <p> tags and skip if <p> has <= 25 char' do
  end

  test 'should get proper license' do
  end

  test 'should get doi from API /contents/README.md' do
  end

  test 'should get latest release from API /releases' do
  end

  test 'should get contributors list from contributors_url' do
  end

  test 'should get prerequisites from HTML page' do
    # if prereq is written in h2 tag
    # if prereq is written in span tag
    # if prereq are in p, ul, ol
    # if prereq is as an id in any tag
    # can be prerreq (es)
  end
