require 'test_helper'

module Fairsharing
  class ClientTest < ActiveSupport::TestCase
    setup do
      @client = Fairsharing::Client.new
      @token_issue_date = Time.new(2022, 12, 1, 16, 7, 18)
      @token = 'eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiIyMjIxMDlhMi0wZWZkLTQ0Y2EtYTYzOC1jNjFmMWZmNmQxYjAiLCJzdWIiOiI4MjI0Iiwic2NwIjoidXNlciIsImF1ZCI6bnVsbCwiaWF0IjoxNjY5OTEwODM4LCJleHAiOjE2Njk5OTcyMzh9.Dv_E6JiyRSrvoOZMHZeQLiEbqYnsTR0qkyrKyWWqb80'
      @expiry = '1669997238'
      @redis = Redis.new(url: TeSS::Config.redis_url)
    end

    test 'should get token' do
      VCR.use_cassette('fairsharing/get_token') do
        token_response = @client.get_token

        data = JSON.parse(token_response.body)
        assert_equal @token, data['jwt']
        assert_equal @expiry, data['expiry'].to_s
      end
    end

    test 'should store token in redis' do
      assert_nil @redis.hget(Fairsharing::Client::REDIS_KEY, 'expiry')
      assert_nil @redis.hget(Fairsharing::Client::REDIS_KEY, 'token')

      VCR.use_cassette('fairsharing/get_token') do
        travel_to(@token_issue_date) do
          @client.token
        end
      end

      assert_equal @expiry, @redis.hget(Fairsharing::Client::REDIS_KEY, 'expiry')
      assert_equal @token, @redis.hget(Fairsharing::Client::REDIS_KEY, 'token')
    end

    test 'should re-use token from @redis' do
      set_cached_token('abcdefg', 1_669_997_273)

      VCR.use_cassette('fairsharing/get_token') do
        travel_to(@token_issue_date) do
          token = @client.token
          assert_equal 'abcdefg', token
        end
      end

      assert_equal '1669997273', @redis.hget(Fairsharing::Client::REDIS_KEY, 'expiry')
      assert_equal 'abcdefg', @redis.hget(Fairsharing::Client::REDIS_KEY, 'token')
    end

    test 'should not re-use token from @redis if expired' do
      set_cached_token('abcdefg', 3.days.ago.to_i)

      VCR.use_cassette('fairsharing/get_token') do
        token = @client.token
        assert_equal @token, token, 'Token should have been renewed'
      end

      assert_equal @expiry, @redis.hget(Fairsharing::Client::REDIS_KEY, 'expiry')
      assert_equal @token, @redis.hget(Fairsharing::Client::REDIS_KEY, 'token')
    end

    test 'can search' do
      set_cached_token

      VCR.use_cassette('fairsharing/search_any_page_1') do
        travel_to(@token_issue_date) do
          res = @client.search(query: 'test')
          assert_equal 25, res.length
          assert_equal 'FAIRsharing record for: Clusters of Orthologous Groups (COG) Analysis Ontology',
                       res.last['attributes']['name']
          assert_equal 1, res.page
          assert_equal 2, res.next_page
          assert_nil res.prev_page
          assert_equal 1, res.first_page
          assert_equal 73, res.last_page
        end
      end
    end

    test 'can get second page of results' do
      set_cached_token

      VCR.use_cassette('fairsharing/search_any_page_2') do
        travel_to(@token_issue_date) do
          res = @client.search(query: 'test', page: 2)
          assert_equal 25, res.length
          assert_equal 'FAIRsharing record for: Logical Observation Identifier Names and Codes',
                       res.last['attributes']['name']
          assert_equal 2, res.page
          assert_equal 3, res.next_page
          assert_equal 1, res.prev_page
          assert_equal 1, res.first_page
          assert_equal 73, res.last_page
        end
      end
    end

    test 'can get final page of results' do
      set_cached_token

      VCR.use_cassette('fairsharing/search_any_page_73') do
        travel_to(@token_issue_date) do
          res = @client.search(query: 'test', page: 73)
          assert_equal 21, res.length
          assert_equal 'FAIRsharing record for: BioPortal', res.last['attributes']['name']
          assert_equal 73, res.page
          assert_nil res.next_page
          assert_equal 72, res.prev_page
          assert_equal 1, res.first_page
          assert_equal 73, res.last_page
        end
      end
    end

    test 'can search subset' do
      set_cached_token

      VCR.use_cassette('fairsharing/search_any_fairdom') do
        travel_to(@token_issue_date) do
          res = @client.search(query: 'fairdom')
          fairdomhub = res[0]
          assert_equal 'FAIRDOMHub', fairdomhub['attributes']['metadata']['name']
          assert_equal 'Database', fairdomhub['attributes']['fairsharing_registry']
          fairdom_standards = res[1]
          assert_equal 'FAIRDOM Community Standards', fairdom_standards['attributes']['metadata']['name']
          assert_equal 'Collection', fairdom_standards['attributes']['fairsharing_registry']
          types = res.map { |r| r['attributes']['fairsharing_registry'] }.uniq
          assert types.length > 1
          assert_equal 37, res.last_page
        end
      end

      VCR.use_cassette('fairsharing/search_database_fairdom') do
        travel_to(@token_issue_date) do
          res = @client.search(query: 'fairdom', type: 'database')
          types = res.map { |r| r['attributes']['fairsharing_registry'] }.uniq
          assert_equal ['Database'], types
          fairdomhub = res[0]
          assert_equal 'FAIRDOMHub', fairdomhub['attributes']['metadata']['name']
          assert_equal 'Database', fairdomhub['attributes']['fairsharing_registry']
          assert_not_equal 'FAIRDOM Community Standards', res[1]['attributes']['metadata']['name']
          assert_equal 21, res.last_page
        end
      end
    end

    test 'empty search results' do
      set_cached_token

      VCR.use_cassette('fairsharing/search_junk') do
        travel_to(@token_issue_date) do
          res = @client.search(query: 'fhdjsfoidsnvoinveoifsodfbsduoifbsduofsef')
          assert_equal 0, res.length
          assert_equal 1, res.page
          assert_nil res.next_page
          assert_nil res.prev_page
          assert_equal 1, res.first_page
          assert_equal 1, res.last_page
        end
      end
    end

    private

    def set_cached_token(token = @token, expiry = @expiry)
      @redis.hset(Fairsharing::Client::REDIS_KEY, 'token', token)
      @redis.hset(Fairsharing::Client::REDIS_KEY, 'expiry', expiry)
    end
  end
end
