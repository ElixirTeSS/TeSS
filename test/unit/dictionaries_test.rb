# frozen_string_literal: true

require 'test_helper'

class DictionariesTest < ActiveSupport::TestCase
  # test the replaceable dictionaries: difficulty, eligibility, and event_types

  setup do
    @dictionaries = TeSS::Config.dictionaries
    reset_dictionaries
  end

  teardown do
    reset_dictionaries
  end

  test 'check target audience dictionary' do
    dic = TargetAudienceDictionary.instance

    assert dic.is_a?(TargetAudienceDictionary)
    refute_nil dic, 'target audience dictionary should exist'

    key = 'dummy'

    assert_nil dic.lookup(key), "#{key}: invalid key was found?"
    key = 'researcher'

    refute_nil dic.lookup(key), "#{key}: key not found"
    key = 'phd'

    refute_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'PhD student', dic.lookup(key)['title'], "#{key}: title not matched"
    key = 'ecr'

    refute_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'Early career researchers and research fellows.', dic.lookup(key)['description'],
                 "#{key}: description not matched"
  end

  test 'check material type dictionary' do
    dic = MaterialTypeDictionary.instance

    assert dic.is_a?(MaterialTypeDictionary)
    refute_nil dic, 'material type dictionary should exist'

    key = 'dummy'

    assert_nil dic.lookup(key), "#{key}: invalid key was found?"
    key = 'presentation'

    refute_nil dic.lookup(key), "#{key}: key not found"
    key = 'activity'

    refute_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'Learning Activity', dic.lookup(key)['title'], "#{key}: title not matched"
    key = 'rubric'

    refute_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'A scoring guide used to evaluate performance.',
                 dic.lookup(key)['description'], "#{key}: description not matched"
  end

  test 'check material status dictionary' do
    dic = MaterialStatusDictionary.instance

    assert dic.is_a?(MaterialStatusDictionary)
    refute_nil dic, 'material status dictionary should exist'

    key = 'dummy'

    assert_nil dic.lookup(key), "#{key}: invalid key was found?"
    key = 'active'

    refute_nil dic.lookup(key), "#{key}: key not found"
    key = 'development'

    refute_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'Under development', dic.lookup(key)['title'], "#{key}: title not matched"
    key = 'archived'

    refute_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'The material has been archived.', dic.lookup(key)['description'], "#{key}: description not matched"
  end

  test 'check cost basis dictionary' do
    dic = CostBasisDictionary.instance

    assert dic.is_a?(CostBasisDictionary)
    refute_nil dic, 'cost basis dictionary should exist'

    key = 'dummy'

    assert_nil dic.lookup(key), "#{key}: invalid key was found?"
    key = 'free'

    refute_nil dic.lookup(key), "#{key}: key not found"
    key = 'hosts'

    refute_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'Cost to non-members', dic.lookup(key)['title'], "#{key}: title not matched"
    key = 'charge'

    refute_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'This event has an associated charge for participants.', dic.lookup(key)['description'],
                 "#{key}: description not matched"
  end

  test 'check default difficulty dictionary' do
    dic = DifficultyDictionary.instance

    assert dic.is_a?(DifficultyDictionary)
    refute_nil dic, 'difficulty dictionary should exist'

    refute_nil dic.lookup('beginner'), 'beginner: not found'
    assert_equal 'Intermediate', dic.lookup('intermediate')['title'],
                 'difficulty level (intermediate) title not matched'
    assert_equal 'Difficulty level not specified', dic.lookup('notspecified')['description'],
                 'difficulty level (notspecified) description not matched'

    assert_nil dic.lookup('master'), 'master: was found!'
  end

  test 'check default eligibility dictionary' do
    dic = EligibilityDictionary.instance

    assert dic.is_a?(EligibilityDictionary)
    refute_nil dic, 'eligibility dictionary should exist'

    assert_nil dic.lookup('open_to_all'), 'open_to_all: was found'

    refute_nil dic.lookup('by_invitation'), 'eligigility level (by_invitation) not found'
    assert_equal 'By invitation', dic.lookup('by_invitation')['title'],
                 'eligigility level (by_invitation) title not matched'
    assert_equal 'Registrations will be accepted in the order received',
                 dic.lookup('first_come_first_served')['description'],
                 'difficulty level (first_come_first_served) description not matched'
  end

  test 'check default event_type dictionary' do
    dic = EventTypeDictionary.instance

    assert dic.is_a?(EventTypeDictionary)
    refute_nil dic, 'event type dictionary should exist'

    assert_nil dic.lookup('dropin'), 'event type (dropin) was found'

    refute_nil dic.lookup('meetings_and_conferences'),
               'event type (meetings_and_conferences) not found'
    assert_equal 'Receptions and networking', dic.lookup('receptions_and_networking')['title'],
                 'event type (receptions_and_networking) title not matched'
    assert_nil dic.lookup('workshops_and_courses')['description'],
               'event type (workshops_and_courses) description was found'
  end

  test 'check fuzzy matching' do
    # keys by default:
    # - workshops_and_courses
    # - receptions_and_networking
    # - meetings_and_conferences
    # - awards_and_prizegivings
    dic = EventTypeDictionary.instance

    assert_equal 'workshops_and_courses', dic.best_match('workshops_and_courses')
    assert_equal 'workshops_and_courses', dic.best_match('workshops')
    # once we start adding 'match' modifiers to the default EventTypeDictionary
    # the below tests may start to fail
    assert_nil dic.best_match('course')
    assert_nil dic.best_match('work')
    assert_nil dic.best_match('wine tasting')
    assert_nil dic.best_match('mooc')
    assert_nil dic.best_match('ceremony')
    assert_nil dic.best_match('networking drink')
    assert_nil dic.best_match('e-learning')
  end

  test 'check alternate event_type dictionary' do
    dic = EventTypeDictionary.instance

    assert dic.is_a?(EventTypeDictionary)
    refute_nil dic, 'event type dictionary should exist'

    @dictionaries['event_types'] = 'event_types_dresa.yml'
    dic.reload

    refute_nil dic.lookup('dropin'), 'event type (dropin) was found'
    assert_equal 'Hackathon', dic.lookup('hackathon')['title'], 'event type (hackathon) title not matched'
  end

  test 'check invalid event_types dictionary' do
    dic = EventTypeDictionary.instance

    assert dic.is_a?(EventTypeDictionary)
    refute_nil dic, 'event type dictionary should exist'

    @dictionaries['event_types'] = 'event_types_dummy.yml'
    dic.reload

    # should reload default
    assert_nil dic.lookup('dropin'), 'event type (dropin) was found'
    refute_nil dic.lookup('meetings_and_conferences'),
               'event type (meetings_and_conferences) not found'
    assert_equal 'Receptions and networking', dic.lookup('receptions_and_networking')['title'],
                 'event type (receptions_and_networking) title not matched'
    assert_nil dic.lookup('workshops_and_courses')['description'],
               'event type (workshops_and_courses) description was found'
  end

  test 'check invalid difficulty dictionary' do
    dic = DifficultyDictionary.instance

    assert dic.is_a?(DifficultyDictionary)
    refute_nil dic, 'difficulty dictionary should exist'

    @dictionaries['difficulty'] = 'difficulty_dummy.yml'
    dic.reload

    # should reload default
    refute_nil dic.lookup('advanced'), 'advanced: not found'
  end

  test 'check invalid eligibility dictionary' do
    dic = EligibilityDictionary.instance

    assert dic.is_a?(EligibilityDictionary)
    refute_nil dic, 'eligibility dictionary should exist'

    @dictionaries['eligibility'] = 'eligibility_dummy.yml'
    dic.reload

    # should reload default
    assert_nil dic.lookup('open_to_all'), 'open_to_all: was found'
    refute_nil dic.lookup('by_invitation'), 'eligigility level (by_invitation) not found'
  end

  test 'check options include descriptions' do
    dic = EligibilityDictionary.instance

    assert dic.is_a?(EligibilityDictionary)
    refute_nil dic, 'eligibility dictionary should exist'

    @dictionaries['eligibility'] = 'eligibility_dresa.yml'
    dic.reload

    # check loaded
    refute_nil dic, 'eligibility (dresa) dictionary should exist'

    ops = dic.options_for_select

    refute_nil ops, 'options should not be nil'
    assert_equal 4, ops.size, 'options size not matched'
    item = 0

    assert_equal 'open_to_all', ops[item][1], "item[#{item}] key not matched"
    assert_equal 'Open to all', ops[item][0], "item[#{item}] title not matched"
    refute_nil ops[item][2], "item[#{item}] description is nil"
    assert_equal 'No restrictions on eligibility', ops[item][2], "item[#{item}] description not matched"
  end

  test 'check options with no descriptions' do
    dic = EventTypeDictionary.instance

    assert dic.is_a?(EventTypeDictionary)
    refute_nil dic, 'event type dictionary should exist'

    # test options for select
    ops = dic.options_for_select

    refute_nil ops, 'options should not be nil'
    assert_equal 4, ops.size, 'options size not matched'
    item = 2

    assert_equal 'receptions_and_networking', ops[item][1], "item[#{item}] key not matched"
    assert_equal 'Receptions and networking', ops[item][0], "item[#{item}] title not matched"
    refute_nil ops[item][2], "item[#{item}] description is nil"
    assert_equal '', ops[item][2], "item[#{item}] description not matched"
  end

  test 'check trainer experience dictionary' do
    dic = TrainerExperienceDictionary.instance

    assert dic.is_a?(TrainerExperienceDictionary)
    refute_nil dic, 'trainer experience dictionary should exist'

    @dictionaries['trainer_experience'] = 'trainer_experience_dummy.yml'
    dic.reload

    # should reload default
    assert_nil dic.lookup('mega'), 'trainer experience (mega) was found'
    refute_nil dic.lookup('none'), 'trainer experience (none) not found'
    assert_equal '10+ years', dic.lookup('expert')['title'],
                 'trainer experience (expert) title not matched'
    assert_equal 'Between 2 and 5 years', dic.lookup('competant')['description'],
                 'trainer experience (none) description was found'
  end

  test 'override dictionaries' do
    original_eligibility = EligibilityDictionary.instance.keys
    original_event_types = EventTypeDictionary.instance.keys
    original_licenses = LicenceDictionary.instance.keys
    modified_eligibility = nil
    modified_event_types = nil
    modified_licenses = nil

    assert_nil EligibilityDictionary.instance.lookup('expression_of_interest')
    assert_nil EventTypeDictionary.instance.lookup('dropin')
    assert_nil LicenceDictionary.instance.lookup('YouTube')

    with_dresa_dictionaries do
      modified_eligibility = EligibilityDictionary.instance.keys
      modified_event_types = EventTypeDictionary.instance.keys
      modified_licenses = LicenceDictionary.instance.keys

      assert_not_equal original_eligibility, modified_eligibility
      assert_not_equal original_event_types, modified_event_types
      assert_not_equal original_licenses, modified_licenses
      assert_equal 'Expression of interest', EligibilityDictionary.instance.lookup('expression_of_interest')['title']
      assert_equal 'Drop-in session or hackyhour', EventTypeDictionary.instance.lookup('dropin')['title']
      assert_equal 'Standard YouTube Licence', LicenceDictionary.instance.lookup('YouTube')['title']
    end

    assert_not_equal modified_eligibility, original_eligibility
    assert_not_equal modified_event_types, original_event_types
    assert_not_equal modified_licenses, original_licenses
    assert_nil EligibilityDictionary.instance.lookup('expression_of_interest')
    assert_nil EventTypeDictionary.instance.lookup('dropin')
    assert_nil LicenceDictionary.instance.lookup('YouTube')
  end
end
