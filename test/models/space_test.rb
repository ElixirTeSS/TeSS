require 'test_helper'

class SpaceTest < ActiveSupport::TestCase
  setup do
    @space = spaces(:plants)
  end

  test 'validate' do
    space = Space.new
    refute space.valid?
    assert space.errors.added?(:title, :blank)
    assert space.errors.added?(:user, :blank)

    user = users(:curator)

    no_host = Space.new(user: user, title: 'hello')
    refute no_host.valid?
    assert no_host.errors.added?(:host, :blank)

    duplicate_host = Space.create(user: user, title: 'hello', host: spaces(:plants).host)
    refute duplicate_host.valid?
    assert duplicate_host.errors.added?(:host, :taken, value: spaces(:plants).host)

    invalid_host = Space.create(user: user, title: 'hello', host: '...')
    refute invalid_host.valid?
    assert invalid_host.errors.added?(:host, :invalid, value: '...')

    invalid_host2 = Space.create(user: user, title: 'hello', host: 'hello world')
    refute invalid_host2.valid?
    assert invalid_host2.errors.added?(:host, :invalid, value: 'hello world')

    invalid_host3 = Space.create(user: user, title: 'hello', host: 'website,com')
    refute invalid_host3.valid?
    assert invalid_host3.errors.added?(:host, :invalid, value: 'website,com')

    invalid_theme = Space.create(user: user, title: 'hello', host: 'space.host', theme: 'disco')
    refute invalid_theme.valid?
    assert invalid_theme.errors.added?(:theme, :inclusion, value: 'disco')

    valid = Space.new(user: user, title: 'hello', host: 'space.host')
    assert valid.valid?
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
    assert @space.errors.added?(:disabled_features, :inclusion)
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

  test 'feature_enabled? is limited by instance enabled features' do
    @space.disabled_features = []
    assert_includes @space.enabled_features, 'events'
    with_settings(feature: { 'events' => true }) do
      assert @space.feature_enabled?('events')
      assert @space.feature_enabled?('materials')
    end

    with_settings(feature: { 'events' => false }) do
      refute @space.feature_enabled?('events')
      assert @space.feature_enabled?('materials')
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

  test 'is_subdomain?' do
    assert @space.is_subdomain?('mytess.training')
    refute @space.is_subdomain?('amytess.training')
    refute @space.is_subdomain?('mytess.com')
    refute @space.is_subdomain?('mytess.training.com')
    refute @space.is_subdomain?('space.mytess.training')
    refute @space.is_subdomain?
    assert Space.new(host: 'test.example.com').is_subdomain?
  end
end
