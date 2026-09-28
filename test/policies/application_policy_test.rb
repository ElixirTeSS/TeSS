require 'test_helper'

class ApplicationPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    @curator = users(:curator) # plant space admin
    @regular_user = users(:regular_user) # requested_material owner
    @another_regular_user = users(:another_regular_user)
    @private_space_owner = users(:private_space_owner)

    @space = spaces(:plants)
    @private_space = spaces(:private_space)

    @requested_material = materials(:requested_material) # does not belongs to plant space and owned by regular_user
    @requested_private_material = materials(:requested_private_material) # belongs to private space and owned by regular_user
  end

  def policy_for(user, record)
    context = Struct.new(:user, :request).new(user)
    ApplicationPolicy.new(context, record)
  end

  test 'site admin always sees unapproved resources' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      assert policy_for(@admin, @requested_material).shown?
    end
  end

  test 'curator can see unapproved resource in public space' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      assert policy_for(@curator, @requested_material).shown?
    end
  end

  test 'curator cannot see unapproved resource in inaccessible private space' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      refute policy_for(@curator, @requested_private_material).shown?
    end
  end

  test 'record owner can see their own unapproved resource' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      assert policy_for(@regular_user, @requested_material).shown?
    end
  end

  test 'another record owner can not see another unapproved resource' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      refute policy_for(@another_regular_user, @requested_material).shown?
    end
  end

  test 'space admin can see unapproved resource in their managed space' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      assert policy_for(@curator, @requested_material).shown?
    end
  end

  test 'another regular user cannot see unapproved resource owned by someone else' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      refute policy_for(@another_regular_user, @requested_material).shown?
    end
  end

  # # --- Scope Tests (resolve_curatable) ---

  test 'resolve_curatable returns all records for site admin' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      context = Struct.new(:user).new(@admin)
      scope = ApplicationPolicy::Scope.new(context, Material).resolve_curatable
      assert_equal Material.count, scope.count
    end
  end

  test 'resolve_curatable returns public and managed private spaces for curator' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      context = Struct.new(:user).new(@curator)
      scope = ApplicationPolicy::Scope.new(context, Material).resolve_curatable

      # Should include materials in public spaces or without space
      scope.each do |material|
        assert material.space.nil? || !material.space.is_private
      end
    end
  end

  test 'resolve_curatable returns only assigned space records for space admin' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      context = Struct.new(:user).new(@private_space_owner)
      scope = ApplicationPolicy::Scope.new(context, Material).resolve_curatable

      scope.each do |material|
        assert_equal @space.id, material.space_id
      end
    end
  end

  test 'resolve_curatable returns no records for regular user without space admin role' do
    with_settings(feature: { spaces:true, material_under_admin_approval: true }) do
      context = Struct.new(:user).new(@regular_user)
      scope = ApplicationPolicy::Scope.new(context, Material).resolve_curatable
      assert_empty scope
    end
  end
end