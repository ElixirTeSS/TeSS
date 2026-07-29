require "application_system_test_case"

class GroupsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @group = groups(:one)
    @admin = users(:admin)
    @owner = users(:regular_user)

    @group.group_memberships.find_or_create_by!(user: @owner) { |membership| membership.owner = true }
  end

  test "visiting the index" do
    sign_in @admin
    visit groups_url
    assert_selector "h1", text: "Groups"
  end

  test "should create group" do
    sign_in @admin
    visit groups_url
    click_on "New group"

    fill_in "Title", with: @group.title

    find("[data-role='autocompleter-input']").fill_in(with: @owner.name)
    find("[data-role='autocompleter-input']").native.send_keys(:down, :enter)

    click_on "Create Group"

    assert_text "Group was successfully created"
    click_on "Back to groups"
  end

  test "should update Group" do
    sign_in @owner
    visit group_url(@group)
    click_on "Edit", match: :first

    fill_in "Title", with: @group.title
    click_on "Update Group"

    assert_text "Group was successfully updated"
    click_on "Back to groups"
  end

  test "should destroy Group" do
    sign_in @owner
    visit group_url(@group)
    click_on "Delete", match: :first

    assert_text "Group was successfully destroyed"
  end
end
