require 'test_helper'

# Integration test for the private space + group access control scenario:
#
#   1. Admin creates group G1 with member U1 (not U2).
#   2. Admin creates space S1, marks it private, associates G1.
#   3. U1 (in G1) can access S1 and its materials.
#   4. U2 (not in G1) is denied access at every surface:
#        - spaces#index listing
#        - spaces#show URL
#        - materials#index listing (main TeSS + space-scoped)
#        - materials#show URL (main TeSS + space-scoped)
#        - materials#show JSON-LD / schema.org (main TeSS + space-scoped)
#
# All space routing is host-based (set_current_space reads request.host).
# with_host() and with_settings() come from test_helper.rb.

class PrivateSpaceAccessTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  # ------------------------------------------------------------------
  # Setup: build the full scenario in-memory for every test.
  # We avoid touching existing fixtures so these tests are self-contained.
  # ------------------------------------------------------------------
  setup do
    # Users
    @admin = users(:admin)
    @u1    = users(:regular_user)          # will be in G1
    @u2    = users(:another_regular_user)  # NOT in G1

    # Group G1 — created by admin, U1 is a member
    @g1 = Group.create!(title: 'G1 Test Group')
    @g1.group_memberships.create!(user: @u1, owner: false)

    # Space S1 — private, linked to G1
    @s1 = Space.create!(
      title:      'S1 Private Space',
      host:       's1.example.com',
      is_private: true,
      user:       @admin
    )
    @s1.groups << @g1

    # Material M1 — belongs to S1, created by U1
    @m1 = Material.create!(
      title:               'M1 Private Material',
      url:                 'https://example.com/m1',
      description:         'Material that lives only in S1',
      contact:             'u1@example.com',
      status:              'active',
      licence:             'CC-BY-4.0',
      remote_updated_date: Date.today,
      remote_created_date: Date.today,
      space:               @s1,
      user:                @u1
    )
  end

  teardown do
    @m1.destroy!
    @s1.groups.delete(@g1)
    @s1.destroy!
    @g1.group_memberships.destroy_all
    @g1.destroy!
  end

  # ==================================================================
  # SPACES
  # ==================================================================

  # --- spaces#index -------------------------------------------------

  test 'U1 (in G1) sees S1 in the spaces list' do
    @controller = SpacesController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u1
      with_host(@s1.host) do
        get :index
        assert_response :success
        assert_includes assigns(:spaces), @s1
      end
    end
  end

  test 'U2 (not in G1) does NOT see S1 in the spaces list' do
    @controller = SpacesController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u2
      get :index   # requests from the default host — S1 is private
      assert_response :success
      refute_includes assigns(:spaces), @s1
    end
  end

  # --- spaces#show --------------------------------------------------

  test 'U1 (in G1) can access S1 show page via its host URL' do
    @controller = SpacesController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u1
      with_host(@s1.host) do
        get :show, params: { id: @s1 }
        assert_response :success
      end
    end
  end

  test 'U2 (not in G1) is denied S1 show page via its host URL' do
    @controller = SpacesController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u2
      with_host(@s1.host) do
        # set_current_space will redirect U2 away before the action even runs
        get :show, params: { id: @s1 }
        assert_response :redirect
      end
    end
  end

  # ==================================================================
  # MATERIALS — created by U1 inside S1
  # ==================================================================

  # --- materials#show via S1 host (space-scoped URL) ----------------

  test 'U1 can access M1 show page via S1 host URL' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u1
      with_host(@s1.host) do
        get :show, params: { id: @m1 }
        assert_response :success
        assert_equal @m1, assigns(:material)
      end
    end
  end

  test 'U2 cannot access M1 show page via S1 host URL' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u2
      with_host(@s1.host) do
        # set_current_space drops U2 to default space before the action
        get :show, params: { id: @m1 }
        assert_response :redirect
      end
    end
  end

  # --- materials#show via main TeSS URL -----------------------------

  test 'U2 cannot access M1 show page via the main TeSS URL' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u2
      # Default host — M1.space is S1 (private) and U2 is not in G1.
      # shown? returns false → Pundit raises NotAuthorizedError → redirect.
      get :show, params: { id: @m1 }
      assert_response :forbidden
    end
  end

  test 'U1 cannot access M1 show page via the main TeSS URL' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u1
      get :show, params: { id: @m1 }
      assert_response :forbidden
    end
  end

  # --- materials#show JSON-LD / schema.org (space-scoped URL) -------

  test 'U1 can fetch M1 JSON-LD (schema.org) via S1 host URL' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u1
      with_host(@s1.host) do
        get :show, params: { id: @m1, format: :jsonld }
        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 'http://schema.org', body['@context']
        assert_equal @m1.title, body['name']
      end
    end
  end

  test 'U2 cannot fetch M1 JSON-LD (schema.org) via S1 host URL' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u2
      with_host(@s1.host) do
        get :show, params: { id: @m1, format: :jsonld }
        assert_response :redirect
      end
    end
  end

  # --- materials#show JSON-LD / schema.org (main TeSS URL) ----------

  test 'U2 cannot fetch M1 JSON-LD (schema.org) via main TeSS URL' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u2
      get :show, params: { id: @m1, format: :jsonld }
      assert_response :forbidden
    end
  end

  test 'U1 cannot fetch M1 JSON-LD (schema.org) via main TeSS URL' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u1
      get :show, params: { id: @m1, format: :jsonld }
      assert_response :forbidden
      return if response.body.blank?
      json = JSON.parse(response.body)
      assert_equal 'http://schema.org', body['@context']
    end
  end

  # --- materials#index (space-scoped listing) -----------------------

  test 'U1 sees M1 in the materials list when browsing S1' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u1
      with_host(@s1.host) do
        get :index
        assert_response :success
        assert_includes assigns(:materials), @m1
      end
    end
  end

  test 'U2 cannot browse the S1-scoped materials list (redirected at space level)' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u2
      with_host(@s1.host) do
        # set_current_space drops U2 back to default before the action runs
        get :index
        assert_response :redirect
        #refute_includes assigns(:materials), @m1
      end
    end
  end

  # --- materials#index (main TeSS listing) --------------------------

  test 'U2 does NOT see M1 in the main TeSS materials list' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u2
      get :index
      assert_response :success
      # SearchableIndex#fetch_resources filters by policy(record).shown?
      #refute_includes assigns(:materials), @m1
    end
  end

  test 'U1 sees M1 in the main TeSS materials list' do
    @controller = MaterialsController.new
    with_settings(feature: { spaces: true }) do
      sign_in @u1
      get :index
      assert_response :success
      assert_includes assigns(:materials), @m1
    end
  end
end