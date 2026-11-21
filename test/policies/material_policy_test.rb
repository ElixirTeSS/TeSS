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
    @requested_private = materials(:requested_private_material)
    @private_space = spaces(:private_space)
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
      refute_includes results, @requested_private
    end
  end

  test 'space admin curator scope includes requested resources in their private space' do
    with_settings(feature: { material_under_admin_approval: true }) do
      @curator.space_roles.create!(space: @private_space, key: 'admin')

      results = resolve_scope(@curator)

      assert_includes results, @requested_private
    end
  end

  test 'Solr index permits private-space curation only to space admins' do
    with_settings(feature: { material_under_admin_approval: true }) do
      refute Material.user_can_curate_unapproved_in_space?(@curator, @private_space)

      @curator.space_roles.create!(space: @private_space, key: 'admin')
      assert Material.user_can_curate_unapproved_in_space?(@curator, @private_space)
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