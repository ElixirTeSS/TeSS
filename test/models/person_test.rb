require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  setup do
    @material = materials(:good_material)
  end

  test 'should create person with name' do
    person = @material.authors.create(name: 'John Doe')
    assert person.valid?
    assert_equal 'John Doe', person.display_name
  end

  test 'should require name' do
    person = Person.new
    refute person.valid?
    assert person.errors.added?(:name, :blank)
  end

  test 'should allow optional orcid' do
    person = @material.authors.create(name: 'John Doe', orcid: '0000-0001-2345-6789')
    assert person.valid?
    assert_equal '0000-0001-2345-6789', person.orcid
  end

  test 'display_name should return name if present' do
    person = Person.new(name: 'Dr. Jane Marie Smith')
    assert_equal 'Dr. Jane Marie Smith', person.display_name
  end

  test 'should link back to resource' do
    person = people(:saskia)
    assert_respond_to person, :resource
    assert_equal materials(:youtube_video_material), person.resource
  end

  test 'should allow optional profile association' do
    person = @material.authors.create(name: 'John Doe')
    assert person.valid?
    assert_nil person.profile
  end

  test 'should automatically link to profile by orcid on save' do
    profile = profiles(:trainer_one_profile)
    # The trainer_one_profile has orcid: https://orcid.org/0000-0002-1825-0097
    person = @material.authors.create(name: 'Josiah Carberry', orcid: 'https://orcid.org/0000-0002-1825-0097')
    assert person.valid?
    assert_equal profile, person.profile
  end

  test 'should automatically link to profile using short orcid format' do
    profile = profiles(:trainer_one_profile)
    # The trainer_one_profile has orcid: https://orcid.org/0000-0002-1825-0097
    person = @material.authors.create(name: 'Josiah Carberry', orcid: '0000-0002-1825-0097')
    assert person.valid?
    assert_equal profile, person.profile
  end

  test 'should not link to profile if no matching orcid' do
    person = @material.authors.create(name: 'John Doe', orcid: '0000-0001-9999-9999')
    assert person.valid?
    assert_nil person.profile
  end

  test 'should should break profile link if orcid removed from person' do
    profile = profiles(:trainer_one_profile)
    # The trainer_one_profile has orcid: https://orcid.org/0000-0002-1825-0097
    person = @material.authors.create(name: 'Josiah Carberry', orcid: '0000-0002-1825-0097', profile: profile)
    assert person.valid?
    assert_equal profile, person.profile

    person.update(orcid: nil)
    assert_nil person.profile
  end

  test 'should should break profile link if orcid removed from profile' do
    profile = profiles(:trainer_one_profile)
    # The trainer_one_profile has orcid: https://orcid.org/0000-0002-1825-0097
    person = @material.authors.create(name: 'Josiah Carberry', orcid: '0000-0002-1825-0097', profile: profile)
    assert person.valid?
    assert_equal profile, person.profile

    profile.update_column(:orcid, nil)

    person.save!
    assert_nil person.profile
  end

  test 'changing orcid should update profile link' do
    profile1 = profiles(:trainer_one_profile)
    profile2 = profiles(:admin_trainer_profile)

    person = @material.authors.build(name: 'John Doe', profile: profile2)
    assert_equal profile2, person.profile

    assert person.update(orcid: profile1.orcid)
    assert_equal profile1, person.profile
  end

  test 'extract attributes from string' do
    p = Person.attr_from_string('Joe Bloggs')
    assert_equal 'Joe Bloggs', p[:name]
    assert_nil p[:orcid]

    p = Person.attr_from_string('  Joe')
    assert_equal 'Joe', p[:name]
    assert_nil p[:orcid]

    p = Person.attr_from_string('Bloggs, Billy-Joe')
    assert_equal 'Bloggs, Billy-Joe', p[:name]
    assert_nil p[:orcid]

    p = Person.attr_from_string('Bloggs, Billy-Joe (orcid: 0000-0002-1825-0097)')
    assert_equal 'Bloggs, Billy-Joe', p[:name]
    assert_equal '0000-0002-1825-0097', p[:orcid]

    p = Person.attr_from_string('Bloggs, Billy-Joe (https://orcid.org/0000-0002-1825-0097)')
    assert_equal 'Bloggs, Billy-Joe', p[:name]
    assert_equal '0000-0002-1825-0097', p[:orcid]

    p = Person.attr_from_string('Bloggs, Billy-Joe 0000-0002-1825-0097')
    assert_equal 'Bloggs, Billy-Joe', p[:name]
    assert_equal '0000-0002-1825-0097', p[:orcid]

    p = Person.attr_from_string('Bloggs, Billy-Joe (0000-0002-1825-0097)')
    assert_equal 'Bloggs, Billy-Joe', p[:name]
    assert_equal '0000-0002-1825-0097', p[:orcid]
  end

  test 'lookup for autocomplete' do
    @material.authors.create!(name: 'John Doe', orcid: '0000-0002-1825-0097')
    @material.authors.create!(name: 'jane Doe')
    @material.authors.create!(name: 'Fred Bloggs')
    materials(:bad_material).authors.create!(name: 'John Doe')
    materials(:youtube_video_material).authors.create!(name: 'John Doe')
    materials(:youtube_video_material).authors.create!(name: 'John Doe', orcid: '0000-0002-1825-0097')
    materials(:youtube_video_material).authors.create!(name: 'John Doe', orcid: '0000-0002-1694-233X')

    # Should select distinct name/ORCID pairs
    johns = Person.query('jo').to_a
    assert_equal 3, johns.length, "Should be 3 - 2 with ORCIDs and 1 without. Should not include duplicates."

    # Other tests
    assert ['John Doe', 'Jane Doe'], Person.query('j').map(&:name).uniq
    assert ['Fred Bloggs'], Person.query('FRED').map(&:name).uniq
    assert [], Person.query('x').map(&:name).uniq
  end

  test 'does not needlessly destroy and recreate associations' do
    assert_difference('Person.count', 1) do
      @material.authors = ['Fred Bloggs']
      assert @material.save
    end

    fred = @material.authors.first

    assert_no_difference('Person.count') do
      @material.authors = ['Fred Bloggs']
      assert @material.save
    end
    assert_equal fred.id, @material.authors.first.id
    assert_equal 'Fred Bloggs', @material.authors.first.name
    assert_nil @material.authors.first.orcid

    assert_no_difference('Person.count') do
      @material.authors = [{ name: 'Fred Bloggs', orcid: '0000-0002-1825-0097' }]
      assert @material.save!
    end
    assert_equal fred.id, @material.authors.first.id
    assert_equal 'Fred Bloggs', @material.authors.first.name
    assert_equal '0000-0002-1825-0097', @material.authors.first.orcid

    assert_no_difference('Person.count') do
      @material.authors = [Person.new(name: 'Freddy Bloggs', orcid: '0000-0002-1825-0097')]
      assert @material.save
    end
    assert_equal fred.id, @material.reload.authors.first.id
    assert_equal 'Freddy Bloggs', @material.authors.first.name
    assert_equal '0000-0002-1825-0097', @material.authors.first.orcid

    # This should replace the person since their name has changed and no ORCID match
    assert_no_difference('Person.count') do
      @material.authors = ['Fred Blobs']
      assert @material.save
    end
    assert_nil Person.find_by_id(fred.id)
    assert_not_equal fred.id, @material.reload.authors.first.id
    assert_equal 'Fred Blobs', @material.authors.first.name
    assert_nil @material.authors.first.orcid
  end
end
