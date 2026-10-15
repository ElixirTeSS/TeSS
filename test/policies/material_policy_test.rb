require 'test_helper'

class MaterialPolicyTest < ActiveSupport::TestCase
  UserContext = Struct.new(:user)

  setup do
    @owner = users(:regular_user)
    @other_user = users(:another_regular_user)
    @admin = users(:admin)
    @curator = users(:curator)

    @approved = materials(:approved_material)
    @requested = materials(:requested_material)
  end

  def resolve_scope(user)
    context = UserContext.new(user)
    MaterialPolicy::Scope.new(context, Material.all).resolve
  end

  test 'anonymous user scope returns only approved materials when feature is enabled' do
    with_settings(feature: { material_under_admin_approval: true }) do
      results = resolve_scope(nil)

      assert_includes results, @approved
      refute_includes results, @requested
    end
  end

  test 'regular non-owner user scope returns only approved materials' do
    with_settings(feature: { material_under_admin_approval: true }) do
      results = resolve_scope(@other_user)

      assert_includes results, @approved
      refute_includes results, @requested
    end
  end

  test 'owner user scope includes their own unapproved materials' do
    with_settings(feature: { material_under_admin_approval: true }) do
      results = resolve_scope(@owner)

      assert_includes results, @approved
      assert_includes results, @requested
    end
  end

  test 'admin user scope includes all materials' do
    with_settings(feature: { material_under_admin_approval: true }) do
      results = resolve_scope(@admin)

      assert_includes results, @approved
      assert_includes results, @requested
    end
  end

  test 'curator user scope includes all materials' do
    with_settings(feature: { material_under_admin_approval: true }) do
      results = resolve_scope(@curator)

      assert_includes results, @approved
      assert_includes results, @requested
    end
  end

  test 'returns all materials when approval feature is disabled' do
    with_settings(feature: { material_under_admin_approval: false }) do
      results = resolve_scope(nil)

      assert_includes results, @approved
      assert_includes results, @requested
    end
  end
end