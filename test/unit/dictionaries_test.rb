require 'test_helper'

class DictionariesTest < ActiveSupport::TestCase
  # test the replaceable dictionaries: difficulty, eligibility, and event_types

  setup do
    # reset default dictionary files
    @dictionaries = TeSS::Config.dictionaries
    @dictionaries['difficulty'] = DifficultyDictionary::DEFAULT_FILE
    @dictionaries['eligibility'] = EligibilityDictionary::DEFAULT_FILE
    @dictionaries['event_type'] = EventTypeDictionary::DEFAULT_FILE
    DifficultyDictionary.instance.reload
    EligibilityDictionary.instance.reload
    EventTypeDictionary.instance.reload
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
    assert_equal "Hackathons", dic.lookup("hackathon")['title'], "event type (hackathon) title not matched"

  end

  test "check invalid event_type dictionary" do
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

end