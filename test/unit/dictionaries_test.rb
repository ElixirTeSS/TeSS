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

  private

  def reset_dictionaries
    # reset default dictionary files
    @dictionaries['difficulty'] = DifficultyDictionary::DEFAULT_FILE
    @dictionaries['eligibility'] = EligibilityDictionary::DEFAULT_FILE
    @dictionaries['event_types'] = EventTypeDictionary::DEFAULT_FILE
    DifficultyDictionary.instance.reload
    EligibilityDictionary.instance.reload
    EventTypeDictionary.instance.reload
  end

end