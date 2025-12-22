require 'test_helper'

class SpaceTest < ActiveSupport::TestCase
  setup do
    @space = spaces(:plants)
  end

  test 'get administrators' do
    admins = @space.administrators
    assert_equal 1, admins.length
    assert_includes admins, users(:space_admin)
  end

  test 'set administrators' do
    user = users(:regular_user)
    another_user = users(:another_regular_user)

    assert_difference('SpaceRole.count', 1) do
      @space.administrators = [user, another_user]
    end

    admins = @space.administrators
    assert_equal 2, admins.length
    assert_includes admins, user
    assert_includes admins, another_user
    assert_not_includes admins, users(:space_admin)

    assert_difference('SpaceRole.count', -2) do
      @space.administrators = []
    end

    assert_empty @space.administrators
  end

  test 'disabled_features defaults to empty array' do
    new_space = Space.new(title: 'Test Space', host: 'test.example.com', user: users(:regular_user))
    assert_equal [], new_space.disabled_features
  end

  test 'disabled_features can be set to valid features' do
    @space.disabled_features = ['events', 'materials']
    assert @space.valid?
    assert_equal ['events', 'materials'], @space.disabled_features
  end

  test 'disabled_features rejects invalid features' do
    @space.disabled_features = ['invalid_feature', 'events']
    assert_not @space.valid?
    assert_includes @space.errors[:disabled_features], :inclusion
  end

  test 'disabled_features allows empty strings' do
    @space.disabled_features = ['events', '', 'materials']
    assert @space.valid?
  end

  test 'feature_enabled? returns true for enabled features' do
    @space.disabled_features = ['materials']
    assert @space.feature_enabled?('events')
    assert @space.feature_enabled?('workflows')
  end

  test 'feature_enabled? returns false for disabled features' do
    @space.disabled_features = ['events', 'materials']
    assert_not @space.feature_enabled?('events')
    assert_not @space.feature_enabled?('materials')
  end

  test 'feature_enabled? returns true when no features are disabled' do
    @space.disabled_features = []
    Space::FEATURES.each do |feature|
      assert @space.feature_enabled?(feature), "Feature #{feature} should be enabled"
    end
  end

  test 'feature_enabled? falls back to TeSS::Config for non-space features' do
    @space.disabled_features = []
    # Test with a feature that's not in Space::FEATURES
    with_settings(feature: { 'custom_feature' => true }) do
      assert @space.feature_enabled?('custom_feature')
    end
    
    with_settings(feature: { 'custom_feature' => false }) do
      assert_not @space.feature_enabled?('custom_feature')
    end
  end

  test 'enabled_features returns all features except disabled ones' do
    @space.disabled_features = ['events', 'materials']
    enabled = @space.enabled_features
    
    assert_not_includes enabled, 'events'
    assert_not_includes enabled, 'materials'
    assert_includes enabled, 'workflows'
    assert_includes enabled, 'collections'
  end

  test 'enabled_features= sets disabled_features to complement' do
    @space.enabled_features = ['events', 'materials']
    
    assert_includes @space.disabled_features, 'workflows'
    assert_includes @space.disabled_features, 'collections'
    assert_includes @space.disabled_features, 'elearning_materials'
    assert_not_includes @space.disabled_features, 'events'
    assert_not_includes @space.disabled_features, 'materials'
  end

  test 'enabled_features= with empty array disables all features' do
    @space.enabled_features = []
    assert_equal Space::FEATURES.sort, @space.disabled_features.sort
  end

  test 'enabled_features= with all features enables all features' do
    @space.enabled_features = Space::FEATURES
    assert_equal [], @space.disabled_features
  end
end
