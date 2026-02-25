require 'test_helper'
require 'sidekiq/testing'

class PersonLinkWorkerTest < ActiveSupport::TestCase
  setup do
    # Needed to handle the image fetch callback on profiles.
    WebMock.stub_request(:any, 'http://example.com').to_return(status: 200, body: 'hi')
  end

  test 'links people to profile when an orcid is authenticated on a profile' do
    person = users(:regular_user).profile
    assert_nil person.orcid

    material = materials(:good_material)
    orcid = '0000-0002-1694-233X'
    author = material.authors.create!(orcid: orcid, full_name: 'Guy Dudeson')
    assert_nil author.profile

    # Auth ORCID
    person.authenticate_orcid(orcid)

    # Perform job
    Sidekiq::Testing.inline! do
      PersonLinkWorker.perform_async([orcid])
    end

    assert_equal person, author.reload.profile
  end

  test 'changes profile link when orcid is associated with a different profile' do
    person_with_orcid = users(:another_regular_user).profile
    orcid = '0000-0002-1694-233X'
    person_with_orcid.authenticate_orcid(orcid)

    new_person = users(:regular_user).profile

    material = materials(:good_material)
    author = material.authors.create!(orcid: orcid, full_name: 'Orcid Haver')
    assert_equal person_with_orcid, author.profile

    # Switch ORCID
    new_person.authenticate_orcid(orcid)

    # Perform job
    Sidekiq::Testing.inline! do
      PersonLinkWorker.perform_async([orcid])
    end

    assert_equal new_person, author.reload.profile
  end

  test 'removes profile link when profile orcid is changed' do
    person_with_orcid = users(:another_regular_user).profile
    orcid = '0000-0002-1694-233X'
    person_with_orcid.authenticate_orcid(orcid)

    material = materials(:good_material)
    author = material.authors.create!(orcid: orcid, full_name: 'Orcid Haver')
    assert_equal person_with_orcid, author.profile

    new_orcid = '0000-0001-5109-3700'

    material = materials(:biojs)
    author2 = material.authors.create!(orcid: new_orcid, full_name: 'No Profile')
    assert_nil author2.profile

    # Switch ORCID
    assert person_with_orcid.authenticate_orcid(new_orcid)

    # Perform job
    Sidekiq::Testing.inline! do
      PersonLinkWorker.perform_async([new_orcid, orcid])
    end

    assert_nil author.reload.profile
    assert_equal person_with_orcid, author2.reload.profile
  end
end
