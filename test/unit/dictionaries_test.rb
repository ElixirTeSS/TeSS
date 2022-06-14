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

  test "check target audience dictionary" do
    dic = TargetAudienceDictionary.instance
    assert dic.is_a?(TargetAudienceDictionary)
    assert_not_nil dic, 'target audience dictionary should exist'

    key = 'dummy'
    assert_nil dic.lookup(key), "#{key}: invalid key was found?"
    key = 'researcher'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    key = 'phd'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'PhD student', dic.lookup(key)['title'], "#{key}: title not matched"
    key = 'ecr'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'Early career researchers and research fellows.', dic.lookup(key)['description'],
                 "#{key}: description not matched"
  end

  test "check material type dictionary" do
    dic = MaterialTypeDictionary.instance
    assert dic.is_a?(MaterialTypeDictionary)
    assert_not_nil dic, 'material type dictionary should exist'

    key = 'dummy'
    assert_nil dic.lookup(key), "#{key}: invalid key was found?"
    key = 'presentation'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    key = 'activity'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'Learning Activity', dic.lookup(key)['title'], "#{key}: title not matched"
    key = 'rubric'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'A scoring guide used to evaluate performance.',
                 dic.lookup(key)['description'], "#{key}: description not matched"
  end

  test "check material status dictionary" do
    dic = MaterialStatusDictionary.instance
    assert dic.is_a?(MaterialStatusDictionary)
    assert_not_nil dic, 'material status dictionary should exist'

    key = 'dummy'
    assert_nil dic.lookup(key), "#{key}: invalid key was found?"
    key = 'active'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    key = 'development'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'Under development', dic.lookup(key)['title'], "#{key}: title not matched"
    key = 'archived'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'The material has been archived.', dic.lookup(key)['description'], "#{key}: description not matched"
  end

  test "check cost basis dictionary" do
    dic = CostBasisDictionary.instance
    assert dic.is_a?(CostBasisDictionary)
    assert_not_nil dic, 'cost basis dictionary should exist'

    key = 'dummy'
    assert_nil dic.lookup(key), "#{key}: invalid key was found?"
    key = 'free'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    key = 'hosts'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'Cost to non-members', dic.lookup(key)['title'], "#{key}: title not matched"
    key = 'charge'
    assert_not_nil dic.lookup(key), "#{key}: key not found"
    assert_equal 'This event has an associated charge for participants.', dic.lookup(key)['description'],
                 "#{key}: description not matched"
  end

  test "check default difficulty dictionary" do
    dic = DifficultyDictionary.instance
    assert dic.is_a?(DifficultyDictionary)
    assert_not_nil dic, "difficulty dictionary should exist"

    assert_not_nil dic.lookup("beginner"), "beginner: not found"
    assert_equal "Intermediate", dic.lookup("intermediate")['title'],
                 "difficulty level (intermediate) title not matched"
    assert_equal "Difficulty level not specified", dic.lookup("notspecified")['description'],
                 "difficulty level (notspecified) description not matched"

    assert_nil dic.lookup("master"), "master: was found!"
  end

  test "check default eligibility dictionary" do
    dic = EligibilityDictionary.instance
    assert dic.is_a?(EligibilityDictionary)
    assert_not_nil dic, "eligibility dictionary should exist"

    assert_nil dic.lookup("open_to_all"), "open_to_all: was found"

    assert_not_nil dic.lookup("by_invitation"), "eligigility level (by_invitation) not found"
    assert_equal "By invitation", dic.lookup("by_invitation")['title'],
                 "eligigility level (by_invitation) title not matched"
    assert_equal "Registrations will be accepted in the order received",
                 dic.lookup("first_come_first_served")['description'],
                 "difficulty level (first_come_first_served) description not matched"

  end

  test "check default event_type dictionary" do
    dic = EventTypeDictionary.instance
    assert dic.is_a?(EventTypeDictionary)
    assert_not_nil dic, "event type dictionary should exist"

    assert_nil dic.lookup("dropin"), "event type (dropin) was found"

    assert_not_nil dic.lookup("meetings_and_conferences"),
                   "event type (meetings_and_conferences) not found"
    assert_equal "Receptions and networking", dic.lookup("receptions_and_networking")['title'],
                 "event type (receptions_and_networking) title not matched"
    assert_nil dic.lookup("workshops_and_courses")['description'],
               "event type (workshops_and_courses) description was found"
  end

  test "check alternate event_type dictionary" do
    dic = EventTypeDictionary.instance
    assert dic.is_a?(EventTypeDictionary)
    assert_not_nil dic, "event type dictionary should exist"

    @dictionaries['event_types'] = 'event_types_dresa.yml'
    dic.reload

    assert_not_nil dic.lookup("dropin"), "event type (dropin) was found"
    assert_equal "Hackathon", dic.lookup("hackathon")['title'], "event type (hackathon) title not matched"

  end

  test "check invalid event_types dictionary" do
    dic = EventTypeDictionary.instance
    assert dic.is_a?(EventTypeDictionary)
    assert_not_nil dic, "event type dictionary should exist"

    @dictionaries['event_types'] = 'event_types_dummy.yml'
    dic.reload

    # should reload default
    assert_nil dic.lookup("dropin"), "event type (dropin) was found"
    assert_not_nil dic.lookup("meetings_and_conferences"),
                   "event type (meetings_and_conferences) not found"
    assert_equal "Receptions and networking", dic.lookup("receptions_and_networking")['title'],
                 "event type (receptions_and_networking) title not matched"
    assert_nil dic.lookup("workshops_and_courses")['description'],
               "event type (workshops_and_courses) description was found"
  end

  test "check invalid difficulty dictionary" do
    dic = DifficultyDictionary.instance
    assert dic.is_a?(DifficultyDictionary)
    assert_not_nil dic, "difficulty dictionary should exist"

    @dictionaries['difficulty'] = 'difficulty_dummy.yml'
    dic.reload

    # should reload default
    assert_not_nil dic.lookup("advanced"), "advanced: not found"
  end

  test "check invalid eligibility dictionary" do
    dic = EligibilityDictionary.instance
    assert dic.is_a?(EligibilityDictionary)
    assert_not_nil dic, "eligibility dictionary should exist"

    @dictionaries['eligibility'] = 'eligibility_dummy.yml'
    dic.reload

    # should reload default
    assert_nil dic.lookup("open_to_all"), "open_to_all: was found"
    assert_not_nil dic.lookup("by_invitation"), "eligigility level (by_invitation) not found"
  end

  test "check options include descriptions" do
    dic = EligibilityDictionary.instance
    assert dic.is_a?(EligibilityDictionary)
    assert_not_nil dic, "eligibility dictionary should exist"

    @dictionaries['eligibility'] = 'eligibility_dresa.yml'
    dic.reload

    # check loaded
    assert_not_nil dic, "eligibility (dresa) dictionary should exist"

    ops = dic.options_for_select
    assert_not_nil ops, "options should not be nil"
    assert_equal 4, ops.size, "options size not matched"
    item = 0
    assert_equal 'open_to_all', ops[item][1], "item[#{item}] key not matched"
    assert_equal 'Open to all', ops[item][0], "item[#{item}] title not matched"
    assert_not_nil ops[item][2], "item[#{item}] description is nil"
    assert_equal 'No restrictions on eligibility', ops[item][2], "item[#{item}] description not matched"
  end

  test "check options with no descriptions" do
    dic = EventTypeDictionary.instance
    assert dic.is_a?(EventTypeDictionary)
    assert_not_nil dic, "event type dictionary should exist"

    # test options for select
    ops = dic.options_for_select
    assert_not_nil ops, "options should not be nil"
    assert_equal 4, ops.size, "options size not matched"
    item = 2
    assert_equal 'receptions_and_networking', ops[item][1], "item[#{item}] key not matched"
    assert_equal 'Receptions and networking', ops[item][0], "item[#{item}] title not matched"
    assert_not_nil ops[item][2], "item[#{item}] description is nil"
    assert_equal '', ops[item][2], "item[#{item}] description not matched"
  end

  test "check trainer experience dictionary" do
    dic = TrainerExperienceDictionary.instance
    assert dic.is_a?(TrainerExperienceDictionary)
    assert_not_nil dic, "trainer experience dictionary should exist"


    @dictionaries['trainer_experience'] = 'trainer_experience_dummy.yml'
    dic.reload

    # should reload default
    assert_nil dic.lookup('mega'), "trainer experience (mega) was found"
    assert_not_nil dic.lookup('none'),"trainer experience (none) not found"
    assert_equal '10+ years', dic.lookup('expert')['title'],
                 "trainer experience (expert) title not matched"
    assert_equal 'Between 2 and 5 years', dic.lookup('competant')['description'],
               "trainer experience (none) description was found"
  end

end