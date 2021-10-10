require 'test_helper'

class MaterialsControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers
  include ActiveJob::TestHelper

  setup do
    mock_images
    mock_biotools
    @material = materials(:good_material)
    @user = users(:regular_user)
    @material.user_id = @user.id
    @material.save!
    @updated_material = {
      title: 'New title',
      description: 'New description',
      url: 'http://new.url.com',
      content_provider_id: ContentProvider.first.id
    }
    @material_with_suggestions = materials(:material_with_suggestions)
    @updated_material_with_suggestions = {
      title: 'New title for suggestion material',
      description: 'New description',
      url: 'http://new.url.com',
      content_provider_id: ContentProvider.first.id
    }
    @failing_material = materials(:failing_material)
    @failing_material.title = 'Fail!'
    @monitor = @failing_material.create_link_monitor(url: @failing_material.url, code: 404, fail_count: 5)
  end

  #Tests
  # INDEX, NEW, EDIT, CREATE, SHOW, BREADCRUMBS, TABS, API CHECKS

  #INDEX TESTS
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:materials)
  end

  test 'should get index with solr enabled' do
    begin
      TeSS::Config.solr_enabled = true

      Material.stub(:search_and_filter, MockSearch.new(Material.all)) do
        get :index, params: { q: 'breakdance for beginners', keywords: 'dancing' }
        assert_response :success
        assert_not_empty assigns(:materials)
      end

    ensure
      TeSS::Config.solr_enabled = false
    end
  end

  test 'should get index as json' do
    @material.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @material.save!

    get :index, params: { format: :json }
    assert_response :success
    assert_not_nil assigns(:materials)
    assert_nothing_raised do
      JSON.parse(response.body)
    end
  end

  test 'should get index as json-api' do
    @material.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @material.save!

    get :index, params: { format: :json_api }
    assert_response :success
    assert_not_nil assigns(:materials)
    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert body['data'].any?
    assert body['meta']['results-count'] > 0
    assert body['meta'].key?('query')
    assert body['meta'].key?('facets')
    assert body['meta'].key?('available-facets')
    assert_equal materials_path, body['links']['self']
  end

  test 'should get faceted index as json-api with search enabled' do
    @material.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @material.save!

    begin
      TeSS::Config.solr_enabled = true

      Material.stub(:search_and_filter, MockSearch.new(Material.all)) do
        get :index, params: { q: 'breakdance for beginners', keywords: 'dancing', format: :json_api }
        assert_response :success
        assert_not_nil assigns(:materials)
        body = nil
        assert_nothing_raised do
          body = JSON.parse(response.body)
        end

        assert body['data'].any?
        assert body['meta']['results-count'] > 0
        assert_equal 'breakdance for beginners', body['meta']['query']
        assert_includes body['meta']['facets']['keywords'], 'dancing'
        assert body['meta']['available-facets'].keys.any?
        assert body['meta']['available-facets'].values.any?
        assert body['links']['self'].include?('dancing')
        assert body['links']['self'].include?('breakdance+for+beginners')
      end
    ensure
      TeSS::Config.solr_enabled = false
    end
  end

  test 'admins should be able to directly load failing records' do
    sign_in users(:admin)
    get :show, params: { id: @failing_material }
    assert_response :success
  end

  test '...and so should users' do
    sign_in users(:regular_user)
    get :show, params: { id: @failing_material }
    assert_response :success
  end

  #NEW TESTS
  test 'should get new' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
  end

  test 'should get new page for logged in users only' do
    #Redirect to login if not logged in
    get :new
    assert_response :redirect
    sign_in users(:regular_user)
    #Success for everyone else
    get :new
    assert_response :success
    sign_in users(:admin)
    get :new
    assert_response :success
  end

  test 'should not get new page for basic users' do
    sign_in users(:basic_user)
    get :new
    assert_response :forbidden
  end

  #EDIT TESTS
  test 'should not get edit page for not logged in users' do
    #Not logged in = Redirect to login
    get :edit, params: { id: @material }
    assert_redirected_to new_user_session_path
  end

  #logged in but insufficient permissions = ERROR
  test 'should get edit for material owner' do
    sign_in users(:regular_user)
    get :edit, params: { id: @material }
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of material logged in = SUCCESS
    sign_in users(:admin)
    get :edit, params: { id: @material }
    assert_response :success
  end

  test 'should get edit for curator' do
    sign_in users(:curator)
    get :edit, params: { id: @material }
    assert_response :success
  end

  test 'should get edit for content provider owner' do
    sign_in users(:curator)
    get :edit, params: { id: materials(:scraper_user_material) }
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    #Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, params: { id: @material }
    assert :forbidden
  end

  test 'should get edit page for approved editor' do
    @material.content_provider.add_editor users(:another_regular_user)
    sign_in users(:another_regular_user)
    get :edit, params: { id: @material }
    assert_response :success
  end

  #CREATE TEST
  test 'should create material for user' do
    sign_in users(:regular_user)
    assert_difference('Material.count') do
      post :create, params: {
        material: {
          doi: @material.doi,
          remote_created_date: @material.remote_created_date,
          remote_updated_date: @material.remote_updated_date,
          description: @material.description,
          title: @material.title,
          url: @material.url,
          licence: @material.licence,
          keywords: @material.keywords,
          contact: @material.contact,
          status: @material.status
        }
      }
    end
    assert_redirected_to material_path(assigns(:material))
    @material.reload
  end

  test 'should create material with all optional attributes' do
    # reference data
    test_title = 'Test of create with optionals via post'
    test_url = 'https://test.of.create/with/optionals_via_post'
    test_material = materials(:material_with_optionals)
    test_provider = content_providers(:portal_provider)
    assert_not_nil test_material, 'missing reference material'
    assert_not_nil test_provider, 'missing reference provider'

    sign_in users(:regular_user)
    assert_difference('Material.count') do
      post :create, params: {
        material: {

          # required attributes
          title: test_title,
          url: test_url,
          description: test_material.description,
          licence: test_material.licence,
          keywords: test_material.keywords,
          contact: test_material.contact,
          status: test_material.status,

          # optional attributes
          content_provider_id: test_provider.id,
          events: test_material.events,
          target_audience: test_material.target_audience,
          resource_type: test_material.resource_type,
          other_types: test_material.other_types,
          version: test_material.version,
          date_created: test_material.date_created,
          date_modified: test_material.date_modified,
          date_published: test_material.date_published,
          doi: test_material.doi,
          subsets: test_material.subsets,
          authors: test_material.authors,
          contributors: test_material.contributors,
          prerequisites: test_material.prerequisites,
          syllabus: test_material.syllabus,
          learning_objectives: test_material.learning_objectives
        }
      }
    end
    assert_redirected_to material_path(assigns(:material))

    # check response
    post :check_exists, params: {
      format: :json,
      material: { title: test_title,
                  url: test_url,
                  content_provider_id: test_provider.id
      }
    }
    assert_response :success
    assert_equal 'application/json', response.content_type, 'response content type not matched'

    # required attributes
    assert_equal test_title, JSON.parse(response.body)['title'], 'title not matched.'
    assert_equal test_url, JSON.parse(response.body)['url'], 'description not matched.'
    assert_equal test_material.description, JSON.parse(response.body)['description'], 'description not matched.'
    assert_equal test_material.licence, JSON.parse(response.body)['licence'], 'licence not matched.'
    assert_equal test_material.contact, JSON.parse(response.body)['contact'], 'contact not matched.'
    assert_equal test_material.keywords, JSON.parse(response.body)['keywords'], 'keywords not matched'
    assert_equal test_material.status, JSON.parse(response.body)['status'], 'status not matched'

    #optional attributes
    assert_equal test_material.doi, JSON.parse(response.body)['doi'], 'doi not matched.'
    assert_equal test_provider.id, JSON.parse(response.body)['content_provider_id'], 'provider not matched'
    assert_equal test_material.resource_type, JSON.parse(response.body)['resource_type'], 'resource_type not matched'
    assert_equal test_material.version, JSON.parse(response.body)['version'], 'version not matched'
    assert_equal test_material.other_types, JSON.parse(response.body)['other_types'], 'other_types not matched'
    #assert_equal test_material.events, JSON.parse(response.body)['events'], 'events not matched'
    assert_equal test_material.target_audience, JSON.parse(response.body)['target_audience'], 'target audience not matched'
    assert_equal test_material.authors, JSON.parse(response.body)['authors'], 'authors not matched'
    assert_equal test_material.contributors, JSON.parse(response.body)['contributors'], 'contributors not matched'
    assert_equal test_material.subsets, JSON.parse(response.body)['subsets'], 'subsets not matched'
    assert_equal test_material.prerequisites, JSON.parse(response.body)['prerequisites'], 'prerequisites not matched'
    assert_equal test_material.syllabus, JSON.parse(response.body)['syllabus'], 'syllabus not matched'
    assert_equal test_material.learning_objectives, JSON.parse(response.body)['learning_objectives'],
                 'learning objectives not matched'
    assert_equal test_material.date_created.to_s("%Y-%m-%d"), JSON.parse(response.body)['date_created'],
                 'date created not matched'
    assert_equal test_material.date_modified.to_s("%Y-%m-%d"), JSON.parse(response.body)['date_modified'],
                 'date modified not matched'
    assert_equal test_material.date_published.to_s("%Y-%m-%d"), JSON.parse(response.body)['date_published'],
                 'date published not matched'

    # reload
    @material.reload
  end

  test 'should create material for admin' do
    sign_in users(:admin)
    assert_difference('Material.count') do
      post :create, params: {
        material: {
          doi: @material.doi,
          remote_created_date: @material.remote_created_date,
          remote_updated_date: @material.remote_updated_date,
          description: @material.description,
          title: @material.title,
          url: @material.url,
          licence: @material.licence,
          keywords: @material.keywords,
          contact: @material.contact,
          status: @material.status
        }
      }
    end
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should not create material for non-logged in user' do
    assert_no_difference('Material.count') do
      post :create, params: {
        material: {
          doi: @material.doi,
          remote_created_date: @material.remote_created_date,
          remote_updated_date: @material.remote_updated_date,
          description: @material.description,
          title: @material.title,
          url: @material.url,
          licence: @material.licence,
          keywords: @material.keywords,
          contact: @material.contact,
          status: @material.status
        }
      }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show material' do
    get :show, params: { id: @material } do
      assert_response :success
      assert assigns(:material)
      assert_select 'fa-commenting-o', :count => 0
    end
  end

  test 'should show material as json' do
    @material.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @material.save!

    get :show, params: { id: @material, format: :json }
    assert_response :success
    assert assigns(:material)

    assert_nothing_raised do
      JSON.parse(response.body)
    end
  end

  test 'should show material as json-api' do
    @material.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @material.save!

    get :show, params: { id: @material, format: :json_api }
    assert_response :success
    assert assigns(:material)

    body = nil
    assert_nothing_raised do
      body = JSON.parse(response.body)
    end

    assert_equal @material.title, body['data']['attributes']['title']
    assert_equal @material.scientific_topic_uris.first, body['data']['attributes']['scientific-topics'].first['uri']
    assert_equal material_path(assigns(:material)), body['data']['links']['self']
  end

  #UPDATE TEST
  test 'should update material' do
    sign_in @material.user
    patch :update, params: { id: @material, material: @updated_material }
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should update material if curator' do
    sign_in users(:curator)
    assert_not_equal @material.user, users(:curator)
    patch :update, params: { id: @material, material: @updated_material }
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should update material if content provider owner' do
    material = materials(:scraper_user_material)
    user = material.content_provider.user
    assert_not_equal material.user, user
    assert_equal material.content_provider.user, user

    sign_in user
    patch :update, params: { id: material, material: @updated_material }
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should not update material if not owner or curator etc.' do
    sign_in users(:collaborative_user)
    assert_not_equal @material.user, users(:collaborative_user)
    patch :update, params: { id: @material, material: @updated_material }
    assert_response :forbidden
  end

  test 'should update material if approved editor' do
    @material.content_provider.add_editor users(:collaborative_user)
    sign_in users(:collaborative_user)
    assert_not_equal @material.user, users(:curator)
    patch :update, params: { id: @material, material: @updated_material }
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should apply edit suggestions to material' do
    sign_in users(:admin)
    assert_empty @material_with_suggestions.scientific_topics
    assert_not_equal @material_with_suggestions.edit_suggestion, nil
    get :show, params: { id: @material_with_suggestions } do
      assert_response :success
      assert_select 'Training Material Example', :count => 1
      assert_select 'fa-commenting-o', :count => 1
    end
    get :edit, params: { id: @material_with_suggestions } do
      assert_response :success
      assert_select 'fa-commenting-o', :count => 0
      assert_select 'a#add-topic-topiconename', :count => 1
      assert_select 'a#add-topic-topictwoname', :count => 1
    end
    patch :update, params: { id: @material_with_suggestions, material: @updated_material_with_suggestions } do
      assert_redirected_to material_path(assigns(:material))
      assert_equal @material_with_suggestions.edit_suggestion, nil
    end
  end

  #DESTROY TEST
  test 'should destroy material owned by user' do
    sign_in users(:regular_user)
    assert_difference('Material.count', -1) do
      delete :destroy, params: { id: @material }
    end
    assert_redirected_to materials_path
  end

  test 'should destroy material when administrator' do
    sign_in users(:admin)
    assert_difference('Material.count', -1) do
      delete :destroy, params: { id: @material }
    end
    assert_redirected_to materials_path
  end

  test 'should destroy material if approved editor' do
    @material.content_provider.add_editor users(:another_regular_user)
    sign_in users(:another_regular_user)
    assert_difference('Material.count', -1) do
      delete :destroy, params: { id: @material }
    end
    assert_redirected_to materials_path
  end

  test 'should not destroy material not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('Material.count') do
      delete :destroy, params: { id: @material }
    end
    assert_response :forbidden
  end

  test 'should destroy material when curator' do
    sign_in users(:curator)
    assert_difference('Material.count', -1) do
      delete :destroy, params: { id: @material }
    end
    assert_redirected_to materials_path
  end

  test 'should destroy material when content provider owner' do
    material = materials(:scraper_user_material)
    user = material.content_provider.user

    sign_in user
    assert_difference('Material.count', -1) do
      delete :destroy, params: { id: material }
    end
    assert_redirected_to materials_path
  end

  #CONTENT TESTS
  #BREADCRUMBS
  test 'breadcrumbs for materials index' do
    get :index
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li[class=active]', :text => /Materials/, :count => 1
    end
  end

  test 'breadcrumbs for showing material' do
    get :show, params: { id: @material }
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Materials/, :count => 1 do
        assert_select 'a[href=?]', materials_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /#{@material.title}/, :count => 1
    end
  end

  test 'breadcrumbs for editing material' do
    sign_in users(:regular_user)
    get :edit, params: { id: @material }
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Materials/, :count => 1 do
        assert_select 'a[href=?]', materials_url, :count => 1
      end
      assert_select 'li', :text => /#{@material.title}/, :count => 1 do
        assert_select 'a[href=?]', material_url(@material), :count => 1
      end
      assert_select 'li[class=active]', :text => /Edit/, :count => 1
    end
  end

  test 'breadcrumbs for creating new material' do
    sign_in users(:regular_user)
    get :new
    assert_response :success
    assert_select 'div.breadcrumbs', :text => /Home/, :count => 1 do
      assert_select 'a[href=?]', root_path, :count => 1
      assert_select 'li', :text => /Materials/, :count => 1 do
        assert_select 'a[href=?]', materials_url, :count => 1
      end
      assert_select 'li[class=active]', :text => /New/, :count => 1
    end
  end

  #OTHER CONTENT
  test 'material has correct tabs' do
    get :show, params: { id: @material }
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', :count => 2 # Material, Activity
      end
    end
  end

  test 'material has correct layout' do
    get :show, params: { id: @material }
    assert_response :success
    assert_select 'h2', :text => @material.title #Has Title
    assert_select 'a.h5[href=?]', @material.url #Has plain written URL
    #assert_select 'a.btn-info[href=?]', materials_path, :count => 1 #Back button
    assert_select 'a.btn-success', :text => "View material", :count => 1 do
      assert_select 'a[href=?]', @material.url, :count => 1 #View Material button
    end
    #Should not show when not logged in
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', material_path(@material), :count => 0 #No Edit
  end

  test 'do not show action buttons when not owner or admin' do
    sign_in users(:another_regular_user)
    get :show, params: { id: @material }
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', material_path(@material), :count => 0 #No Edit
  end

  test 'show action buttons when owner' do
    sign_in users(:regular_user)
    get :show, params: { id: @material }
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 1
    assert_select 'a.btn-danger[href=?]', material_path(@material), :text => 'Delete', :count => 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)
    get :show, params: { id: @material }
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 1
    assert_select 'a.btn-danger[href=?]', material_path(@material), :text => 'Delete', :count => 1
  end

  test 'show action buttons when approved editor' do
    @material.content_provider.add_editor users(:another_regular_user)
    sign_in users(:another_regular_user)
    get :show, params: { id: @material }
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 1
    assert_select 'a.btn-danger[href=?]', material_path(@material), :text => 'Delete', :count => 1
  end

  #API Actions
  test 'should find existing material by title and content provider' do
    post :check_exists, params: {
      format: :json,
      material: { title: @material.title,
                  url: 'whatever.com',
                  content_provider_id: @material.content_provider_id
      }
    }
    assert_response :success
    assert_equal(JSON.parse(response.body)['id'], @material.id)
  end

  test 'should find existing material by url' do
    post :check_exists, params: {
      format: :json,
      material: { title: 'whatever',
                  url: @material.url,
                  content_provider_id: @material.content_provider_id }
    }
    assert_response :success
    assert_equal(JSON.parse(response.body)['id'], @material.id)
  end

  test 'should return nothing when material does not exist' do
    post :check_exists, params: {
      format: :json,
      material: { url: 'http://no-such-url.com' }
    }
    assert_response :success
    assert_equal '{}', response.body
  end

  test 'should render properly when no url supplied' do
    post :check_exists, params: {
      format: :json,
      material: { url: nil }
    }
    assert_response :success
    assert_equal '{}', response.body
  end

  test 'should display filters on index' do
    get :index
    assert_select 'h4.nav-heading', :text => /Content provider/, :count => 0
    assert_select 'div.list-card', :count => Material.count
  end

  test 'should create new material through API' do
    scraper_role = Role.fetch('scraper_user')
    scraper_user = User.where(:role_id => scraper_role.id).first
    material_title = 'horse'
    assert scraper_user
    assert_difference('Material.count') do
      post :create, params: {
        user_token: scraper_user.authentication_token,
        user_email: scraper_user.email,
        material: {
          title: material_title,
          url: 'http://horse.com',
          description: 'I love horses',
          contact: 'default contact',
          doi: 'https://doi.org/10.1001/RSE.2.190',
          licence: 'CC-BY-4.0',
          keywords: ['scraped', 'through', 'api'],
          status: 'active'
        },
        format: 'json'
      }
    end
    assert_equal material_title, JSON.parse(response.body)['title']
  end

  test 'should not create new material without valid authentication token' do
    scraper_role = Role.fetch('scraper_user')
    scraper_user = User.where(:role_id => scraper_role.id).first
    assert scraper_user

    assert_no_difference('Material.count') do
      post :create, params: {
        user_token: 'made up authentication token',
        user_email: scraper_user.email,
        material: {
          title: 'material_title',
          url: 'http://horse.com',
          description: 'All about horses',
          contact: 'default contact',
          doi: 'https://doi.org/10.1001/RSE.2.190',
          licence: 'CC-BY-4.0',
          keywords: %{ invalid authtoken },
          status: 'active'
        },
        format: 'json'
      }
    end
    assert_response 401
  end

  test 'should update existing material through API' do
    user = users(:scraper_user)
    material = materials(:scraper_user_material)

    new_title = "totally new title"
    assert_no_difference('Material.count') do
      patch :update, params: {
        user_token: user.authentication_token,
        user_email: user.email,
        material: {
          title: new_title,
          url: material.url,
          description: material.description
        },
        id: material.id,
        format: 'json'
      }
    end
    assert_not_equal material.title, JSON.parse(response.body)['title']
    assert_equal new_title, JSON.parse(response.body)['title']
  end

  test 'should not update non scraper owner through API' do
    user = users(:regular_user)
    other_user = users(:another_regular_user)
    material = user.materials.first

    new_title = "totally new title"
    assert_no_difference('Material.count') do
      patch :update, params: {
        user_token: other_user.authentication_token,
        user_email: other_user.email,
        material: {
          title: new_title,
          url: material.url,
          description: material.description
        },
        id: material.id,
        format: 'json'
      }
    end
    assert_response 401
  end

  test 'should add material to multiple packages' do
    sign_in @material.user
    package1 = packages(:one)
    package1_material_count = package1.materials.count
    package2 = packages(:two)
    @material.packages = []
    @material.save!
    assert_difference('@material.packages.count', 2) do
      post :update_packages, params: {
        id: @material.id,
        material: {
          package_ids: [package1.id, package2.id]
        }
      }
    end
    assert_in_delta(package1.materials.count, package1_material_count, 1)
  end

  test 'should remove material from packages' do
    sign_in @material.user
    package1 = packages(:one)
    package1_material_count = package1.materials.count
    package2 = packages(:two)
    @material.packages << [package1, package2]
    @material.save

    assert_difference('@material.packages.count', -2) do
      post :update_packages, params: {
        id: @material.id,
        material: {
          package_ids: ['']
        }
      }
    end
    assert_in_delta(package1.materials.count, package1_material_count, 1)
  end

  test 'should add external resource to material' do
    sign_in @material.user

    assert_difference('ExternalResource.count', 1) do
      patch :update, params: {
        id: @material,
        material: {
          title: 'New title',
          description: 'New description',
          url: 'http://new.url.com',
          content_provider_id: ContentProvider.first.id,
          external_resources_attributes: { "1" => { title: 'Cool link', url: 'https://tess.elixir-uk.org/', _destroy: '0' } }
        }
      }
    end

    assert_redirected_to material_path(assigns(:material))
    resource = assigns(:material).external_resources.first
    assert_equal 'Cool link', resource.title
    assert_equal 'https://tess.elixir-uk.org/', resource.url
  end

  test 'should remove external resource from material' do
    material = materials(:material_with_external_resource)
    resource = material.external_resources.first
    count = material.external_resources.count
    sign_in material.user

    assert_difference('ExternalResource.count', -1) do
      patch :update, params: {
        id: material,
        material: {
          title: 'New title',
          description: 'New description',
          url: 'http://new.url.com',
          content_provider_id: ContentProvider.first.id,
          external_resources_attributes: { "0" => { id: resource.id, _destroy: '1' } }
        }
      }
    end

    assert_redirected_to material_path(assigns(:material))
    assert_equal count - 1, assigns(:material).external_resources.count
  end

  test 'should modify external resource from material' do
    material = materials(:material_with_external_resource)
    resource = material.external_resources.first
    sign_in material.user

    assert_no_difference('ExternalResource.count') do
      patch :update, params: {
        id: material,
        material: {
          title: 'New title',
          description: 'New description',
          url: 'http://new.url.com',
          content_provider_id: ContentProvider.first.id,
          external_resources_attributes: { "1" => { id: resource.id, title: 'Cool link',
                                                    url: 'http://www.reddit.com', _destroy: '0' } }
        }
      }
    end

    assert_redirected_to material_path(assigns(:material))
    assert_equal 'Cool link', resource.reload.title
    assert_equal 'http://www.reddit.com', resource.url
  end

  # TODO: SOLR tests will not run on TRAVIS. Explore stratergy for testing solr
=begin
      test 'should return matching materials' do
        get 'index', :format => :json, :q => 'training'
        assert_response :success
        assert response.body.size > 0
      end

      test 'should return no matching materials' do
        get 'index', :format => :json, :q => 'kdfsajfklasdjfljsdfljdsfjncvmn'
        assert_response :success
        assert_equal(response.body,'[]')
        end
=end
  test 'finds multiple preferred labels' do
    topic_one = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0154')
    topic_two = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0078')
    topics = [topic_one.preferred_label, topic_two.preferred_label]
    @material.scientific_topic_names = topics
    assert_not_empty @material.scientific_topics
    assert_equal [topic_one, topic_two], @material.scientific_topics
  end
  test 'finds single preferred label' do
    topic_one = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0154')
    topics = topic_one.preferred_label
    @material.scientific_topic_names = topics
    assert_not_empty @material.scientific_topics
    assert_equal [topic_one], @material.scientific_topics
  end

  test 'find scientific topic that has an exact synonym of parameter' do
    synonym_topic = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_0092')
    topics = synonym_topic.has_exact_synonym
    @material.scientific_topic_names = topics
    assert_equal [synonym_topic], @material.scientific_topics
  end

  test 'find scientific topic that is a narrow synonym of parameter' do
    narrow_topic = EDAM::Ontology.instance.lookup('http://edamontology.org/topic_3557')
    topics = narrow_topic.has_narrow_synonym
    @material.scientific_topic_names = topics
    assert_equal [narrow_topic], @material.scientific_topics
  end

  test 'set topics to nil if empty array passed' do
    topics = []
    @material.scientific_topic_names = topics
    assert_empty @material.scientific_topics
  end

  test 'should sanitize descriptions when creating material' do
    sign_in @user

    assert_difference('Material.count', 1) do
      post :create, params: {
        material: { description: '<b>hi</b><script>alert("hi!");</script>',
                    title: 'Insanity',
                    url: 'http://www.example.com/sanity/0',
                    doi: 'https://doi.org/10.1100/RSE.2019.23',
                    licence: 'CC-BY-4.0',
                    keywords: ['insanity', 'sanitized', 'sanitary'],
                    contact: 'default contact',
                    status: 'development'
        }
      }
    end

    assert_redirected_to material_path(assigns(:material))
    assert_equal 'hi', assigns(:material).description
  end

  test 'should log parameter changes when updating a material' do
    sign_in @material.user
    @material.activities.destroy_all

    # 5 = 4 for parameters + 1 for update
    assert_difference('PublicActivity::Activity.count', 5) do
      patch :update, params: { id: @material, material: @updated_material }
    end

    assert_equal 1, @material.activities.where(key: 'material.update').count
    assert_equal 4, @material.activities.where(key: 'material.update_parameter').count

    parameters = @material.activities.where(key: 'material.update_parameter').map(&:parameters)
    title_activity = parameters.detect { |p| p[:attr] == 'title' }
    url_activity = parameters.detect { |p| p[:attr] == 'url' }
    description_activity = parameters.detect { |p| p[:attr] == 'description' }
    content_provider_activity = parameters.detect { |p| p[:attr] == 'content_provider_id' }

    assert_equal 'New title', title_activity[:new_val]
    assert_equal 'http://new.url.com', url_activity[:new_val]
    assert_equal 'New description', description_activity[:new_val]
    assert_equal ContentProvider.first.id, content_provider_activity[:new_val]
    assert_equal ContentProvider.first.title, content_provider_activity[:association_name]

    old_controller = @controller
    @controller = ActivitiesController.new

    get :index, params: { material_id: @material }, xhr: true

    assert_select '.activity', count: 6 # +1 because they are wrapped in a .activity div for some reason...

    @controller = old_controller
  end

  test 'parameter log activity works when removing an association' do
    sign_in @material.user
    @material.activities.destroy_all

    assert_difference('PublicActivity::Activity.count', 2) do
      # 2 = 1 for parameters + 1 for update
      patch :update, params: { id: @material, material: { content_provider_id: nil } }
    end

    assert_equal 1, @material.activities.where(key: 'material.update').count
    assert_equal 1, @material.activities.where(key: 'material.update_parameter').count

    parameters = @material.activities.where(key: 'material.update_parameter').map(&:parameters)
    content_provider_activity = parameters.detect { |p| p[:attr] == 'content_provider_id' }

    assert content_provider_activity[:new_val].blank?
    assert content_provider_activity[:association_name].blank?

    old_controller = @controller
    @controller = ActivitiesController.new

    get :index, params: { material_id: @material }, xhr: true

    assert_select '.activity', count: 3 # +1 because they are wrapped in a .activity div for some reason...

    @controller = old_controller
  end

  test 'should not log an update when only boring fields have changed' do
    sign_in @material.user
    @material.activities.destroy_all

    assert_no_difference('PublicActivity::Activity.count') do
      patch :update, params: { id: @material, material: { last_scraped: Time.now } }
    end
  end

  test 'can assign nodes by name' do
    sign_in users(:regular_user)

    assert_difference('Material.count') do
      post :create, params: {
        material: {
          description: @material.description,
          title: @material.title,
          url: @material.url,
          node_names: [nodes(:westeros).name, nodes(:good).name],
          doi: @material.doi,
          licence: @material.licence,
          keywords: @material.keywords,
          contact: @material.contact,
          status: @material.status
        }
      }
    end
    assert_redirected_to material_path(assigns(:material))

    assert_includes assigns(:material).node_ids, nodes(:westeros).id
    assert_includes assigns(:material).node_ids, nodes(:good).id
  end

  test 'can lock fields' do
    sign_in @material.user
    assert_difference('FieldLock.count', 2) do
      patch :update, params: { id: @material, material: { title: 'hi', locked_fields: ['title', 'description'] } }
    end

    assert_redirected_to material_path(assigns(:material))
    assert_equal 2, assigns(:material).locked_fields.count
    assert assigns(:material).field_locked?(:title)
    assert assigns(:material).field_locked?(:description)
    refute assigns(:material).field_locked?(:url)
  end

  test 'scraper cannot overwrite locked fields' do
    user = users(:scraper_user)
    material = materials(:scraper_user_material)
    material.locked_fields = [:title]
    material.save!

    assert_no_difference('Material.count') do
      patch :update, params: {
        user_token: user.authentication_token,
        user_email: user.email,
        material: {
          title: 'new title',
          url: material.url,
          description: 'new description'
        },
        id: material.id,
        format: 'json'
      }
    end

    parsed_response = JSON.parse(response.body)
    assert_equal material.title, parsed_response['title'], 'Title should not have changed'
    assert_equal 'new description', parsed_response['description']
  end

  test 'normal user can overwrite locked fields' do
    @material.locked_fields = [:title]
    @material.save!

    sign_in @material.user
    patch :update, params: { id: @material, material: { title: 'new title' } }
    assert_redirected_to material_path(assigns(:material))

    assert_equal 'new title', assigns(:material).title
  end

  test 'should count index results' do
    begin
      TeSS::Config.solr_enabled = true

      materials = Material.all

      Material.stub(:search_and_filter, MockSearch.new(materials)) do
        get :count, params: { format: :json }
        output = JSON.parse(response.body)

        assert_response :success
        assert_equal materials.count, output['count']
        assert_equal materials_url, output['url']
      end
    ensure
      TeSS::Config.solr_enabled = false
    end
  end

  test 'should count filtered results' do
    begin
      TeSS::Config.solr_enabled = true

      materials = Material.limit(3)

      Material.stub(:search_and_filter, MockSearch.new(materials)) do
        get :count, params: { q: 'test', keywords: 'dolphins', blabla: 'booboo', format: :json }
        output = JSON.parse(response.body)

        assert_response :success
        assert_equal materials.count, output['count']
        assert_equal materials_url(q: 'test', keywords: 'dolphins'), output['url']
        assert_equal 'dolphins', output['params']['keywords']
      end
    ensure
      TeSS::Config.solr_enabled = false
    end
  end

  test 'should approve topic for curator' do
    sign_in users(:curator)

    assert_empty @material.scientific_topic_names

    suggestion = @material.build_edit_suggestion
    suggestion.scientific_topic_uris = ['http://edamontology.org/topic_0622']
    suggestion.save!

    assert_difference('EditSuggestion.count', -1) do
      post :add_term, params: { id: @material.id, field: 'scientific_topics', uri: 'http://edamontology.org/topic_0622' }
    end

    assert_response :success

    assert_equal ['Genomics'], @material.reload.scientific_topic_names
    assert_nil @material.reload.edit_suggestion
  end

  test 'should reject topic for curator' do
    sign_in users(:curator)

    assert_empty @material.scientific_topic_names

    suggestion = @material.build_edit_suggestion
    suggestion.scientific_topic_uris = ['http://edamontology.org/topic_0622']
    suggestion.data_fields = {}
    suggestion.data_fields[:latitude] = '53.141969'
    suggestion.data_fields[:longitude] = '0.3418338'
    suggestion.save!

    assert_difference('EditSuggestion.count', 0) do
      post :reject_term, params: { id: @material.id, field: 'scientific_topics', uri: 'http://edamontology.org/topic_0622' }
    end

    assert_response :success

    assert_difference('EditSuggestion.count', 0) do
      post :reject_data, params: { id: @material.id, data_field: 'latitude', data_value: '53.141969' }
    end

    assert_response :success

    assert_difference('EditSuggestion.count', -1) do
      post :reject_data, params: { id: @material.id, data_field: 'longitude', data_value: '0.3418338' }
    end

    assert_response :success

    assert_empty @material.reload.scientific_topic_names
    assert_nil @material.reload.edit_suggestion
  end

  test 'should not approve topic for unprivileged user' do
    sign_in users(:another_regular_user)

    assert_empty @material.scientific_topic_names

    suggestion = @material.build_edit_suggestion
    suggestion.scientific_topic_uris = ['http://edamontology.org/topic_0622']
    suggestion.save!

    assert_no_difference('EditSuggestion.count') do
      post :add_term, params: { id: @material.id, field: 'scientific_topics', uri: 'http://edamontology.org/topic_0622' }
    end

    assert_response :forbidden

    assert_empty @material.reload.scientific_topic_names
    assert_equal ['Genomics'], @material.reload.edit_suggestion.scientific_topic_names
  end

  test 'should not reject topic for unprivileged user' do
    sign_in users(:another_regular_user)

    assert_empty @material.scientific_topic_names

    suggestion = @material.build_edit_suggestion
    suggestion.scientific_topic_uris = ['http://edamontology.org/topic_0622']
    suggestion.save!

    assert_no_difference('EditSuggestion.count') do
      post :reject_term, params: { id: @material.id, field: 'scientific_topics', uri: 'http://edamontology.org/topic_0622' }
    end

    assert_response :forbidden

    assert_empty @material.reload.scientific_topic_names
    assert_equal ['Genomics'], @material.reload.edit_suggestion.scientific_topic_names
  end

  test 'should trigger notification when unverified user creates material' do
    sign_in users(:unverified_user)

    assert_enqueued_jobs 1 do
      assert_difference('Material.count') do
        post :create, params: {
          material: { description: @material.description,
                      title: @material.title,
                      url: 'http://example.com/dodgy-event',
                      doi: 'https://doi.org/10.10067/SEA.2019.22',
                      licence: 'CC-BY-4.0',
                      keywords: %w{ dodgy event },
                      contact: 'default contact',
                      status: 'archived'
          }
        }
      end
    end

    assert_redirected_to material_path(assigns(:material))
    @material.reload
  end

  test 'should not trigger notification if unverified user already created content' do
    sign_in users(:unverified_user)
    users(:unverified_user).materials.create!(description: @material.description,
                                              title: @material.title, url: 'http://example.com/dodgy-event',
                                              doi: 'https://doi.org/10.10067/SEA.2019.22', status: 'active',
                                              licence: 'CC-BY-4.0', contact: 'default contact',
                                              keywords: %w{ dodgy event unverified user })

    assert_enqueued_jobs 0 do
      assert_difference('Material.count') do
        post :create, params: {
          material: { description: @material.description,
                      title: @material.title, url: 'http://example.com/dodgy-event-2',
                      licence: 'CC-BY-4.0', contact: 'default contact', status: 'active',
                      doi: 'https://doi.org/10.10067/SEA.2019.22',
                      keywords: %w{ another dodgy event }
          }
        }
      end
    end

    assert_redirected_to material_path(assigns(:material))
    @material.reload
  end

  test 'can view material with external resources' do
    material = materials(:material_with_external_resource)
    get :show, params: { id: material }
    assert_response :success

    assert_select '.external-resources-box div.bounding-box', count: material.external_resources.count
  end

  test 'should show identifiers dot org button for material' do
    get :show, params: { id: @material }

    assert_response :success
    assert_select '.identifiers-button'
    assert_select '#identifiers-link[value=?]', "http://example.com/identifiers/banana:m#{@material.id}"
  end

  test 'should not add extra subset on error' do
    title = 'Test Material with errors'
    url = 'https://dresa.org.au/test-material-with-errors/'
    desc = 'No description'
    keywords = %w{ test materials with errors }
    subsets = %w{ part-one part-two }
    assert_equal 2, subsets.size, 'before: subsets items count not matched'

    # create material without 3 required fields
    sign_in users(:regular_user)
    assert_no_difference('Material.count') do
      post :create, params: {
        material: {
          title: title,
          url: url,
          description: desc,
          keywords: keywords,
          subsets: subsets
        }
      }

      assert_response :success
      material = assigns(:material)
      assert_equal 3, material.errors.size, 'invalid number of errors'
      assert_not_nil material.subsets, 'subsets is nil'
      assert_equal 2, material.subsets.size, 'after: subsets items count not matched'
    end

  end
end
