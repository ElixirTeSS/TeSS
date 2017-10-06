require 'test_helper'

class MaterialsControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  setup do
    mock_images
    mock_biotools
    @material = materials(:good_material)
    @user = users(:regular_user)
    @material.user_id = @user.id
    @material.save!
    @updated_material = {
        title: 'New title',
        short_description: 'New description',
        url: 'http://new.url.com',
        content_provider_id: ContentProvider.first.id
    }
    @material_with_suggestions = materials(:material_with_suggestions)
    @updated_material_with_suggestions = {
        title: 'New title for suggestion material',
        short_description: 'New description',
        url: 'http://new.url.com',
        content_provider_id: ContentProvider.first.id
    }
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
        get :index, q: 'breakdance for beginners', keywords: 'dancing'
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

    get :index, format: :json
    assert_response :success
    assert_not_nil assigns(:materials)
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

  #EDIT TESTS
  test 'should not get edit page for not logged in users' do
    #Not logged in = Redirect to login
    get :edit, id: @material
    assert_redirected_to new_user_session_path
  end

    #logged in but insufficient permissions = ERROR
  test 'should get edit for material owner' do
    sign_in users(:regular_user)
    get :edit, id: @material
    assert_response :success
  end

  test 'should get edit for admin' do
    #Owner of material logged in = SUCCESS
    sign_in users(:admin)
    get :edit, id: @material
    assert_response :success
  end

  test 'should get edit for curator' do
    sign_in users(:curator)
    get :edit, id: @material
    assert_response :success
  end

  test 'should get edit for content provider owner' do
    sign_in users(:curator)
    get :edit, id: materials(:scraper_user_material)
    assert_response :success
  end

  test 'should not get edit page for non-owner user' do
    #Administrator = SUCCESS
    sign_in users(:another_regular_user)
    get :edit, id: @material
    assert :forbidden
  end

  #CREATE TEST
  test 'should create material for user' do
    sign_in users(:regular_user)
    assert_difference('Material.count') do
      post :create, material: { doi: @material.doi,  remote_created_date: @material.remote_created_date, remote_updated_date: @material.remote_updated_date, short_description: @material.short_description, title: @material.title, url: @material.url }
    end
    assert_redirected_to material_path(assigns(:material))
    @material.reload
  end

  test 'should create material for admin' do
    sign_in users(:admin)
    assert_difference('Material.count') do
      post :create, material: { doi: @material.doi,  remote_created_date: @material.remote_created_date, remote_updated_date: @material.remote_updated_date, short_description: @material.short_description, title: @material.title, url: @material.url }
    end
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should not create material for non-logged in user' do
    assert_no_difference('Material.count') do
      post :create, material: { doi: @material.doi,  remote_created_date: @material.remote_created_date, remote_updated_date: @material.remote_updated_date, short_description: @material.short_description, title: @material.title, url: @material.url }
    end
    assert_redirected_to new_user_session_path
  end

  #SHOW TEST
  test 'should show material' do
    get :show, id: @material do
      assert_response :success
      assert assigns(:material)
      assert_select 'fa-commenting-o', :count => 0
    end
  end

  test 'should show material as json' do
    @material.scientific_topic_uris = ['http://edamontology.org/topic_0654']
    @material.save!

    get :show, id: @material, format: :json do
      assert_response :success
      assert assigns(:material)
    end
  end


  #UPDATE TEST
  test 'should update material' do
    sign_in @material.user
    # patch :update, id: @material, material: { doi: @material.doi,  remote_created_date: @material.remote_created_date,  remote_updated_date: @material.remote_updated_date, short_description: @material.short_description, title: @material.title, url: @material.url }
    patch :update, id: @material, material: @updated_material
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should update material if curator' do
    sign_in users(:curator)
    assert_not_equal @material.user, users(:curator)
    patch :update, id: @material, material: @updated_material
    assert_redirected_to material_path(assigns(:material))
  end

  test 'should update material if content provider owner' do
    material = materials(:scraper_user_material)
    user = material.content_provider.user

    assert_not_equal material.user, user
    assert_equal material.content_provider.user, user

    sign_in user

    patch :update, id: material, material: @updated_material

    assert_redirected_to material_path(assigns(:material))
  end

  test 'should not update material if not owner or curator etc.' do
    sign_in users(:collaborative_user)
    assert_not_equal @material.user, users(:collaborative_user)
    patch :update, id: @material, material: @updated_material
    assert_response :forbidden
  end

  test 'should apply edit suggestions to material' do
    sign_in users(:admin)
    assert_empty @material_with_suggestions.scientific_topics
    assert_not_equal @material_with_suggestions.edit_suggestion, nil
    get :show, id: @material_with_suggestions do
      assert_response :success
      assert_select 'Training Material Example', :count => 1
      assert_select 'fa-commenting-o', :count => 1
    end
    get :edit, id: @material_with_suggestions do
      assert_response :success
      assert_select 'fa-commenting-o', :count => 0
      assert_select 'a#add-topic-topiconename', :count => 1
      assert_select 'a#add-topic-topictwoname', :count => 1
    end
    patch :update, id: @material_with_suggestions, material: @updated_material_with_suggestions do
      assert_redirected_to material_path(assigns(:material))
      assert_equal @material_with_suggestions.edit_suggestion, nil
    end
  end


  #DESTROY TEST
  test 'should destroy material owned by user' do
    sign_in users(:regular_user)
    assert_difference('Material.count', -1) do
      delete :destroy, id: @material
    end
    assert_redirected_to materials_path
  end

  test 'should destroy material when administrator' do
    sign_in users(:admin)
    assert_difference('Material.count', -1) do
      delete :destroy, id: @material
    end
    assert_redirected_to materials_path
  end

  test 'should not destroy material not owned by user' do
    sign_in users(:another_regular_user)
    assert_no_difference('Material.count') do
      delete :destroy, id: @material
    end
    assert_response :forbidden
  end

  test 'should destroy material when curator' do
    sign_in users(:curator)
    assert_difference('Material.count', -1) do
      delete :destroy, id: @material
    end
    assert_redirected_to materials_path
  end

  test 'should destroy material when content provider owner' do
    material = materials(:scraper_user_material)
    user = material.content_provider.user

    sign_in user
    assert_difference('Material.count', -1) do
      delete :destroy, id: material
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
    get :show, :id => @material
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
    get :edit, id: @material
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
    get :show, :id => @material
    assert_response :success
    assert_select 'ul.nav-tabs' do
      assert_select 'li' do
        assert_select 'a[data-toggle="tab"]', :count => 2 # Material, Activity
      end
    end
  end

  test 'material has correct layout' do
    get :show, :id => @material
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
    get :show, :id => @material
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 0 #No Edit
    assert_select 'a.btn-danger[href=?]', material_path(@material), :count => 0 #No Edit
  end

  test 'show action buttons when owner' do
    sign_in users(:regular_user)
    get :show, :id => @material
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 1
    assert_select 'a.btn-danger[href=?]', material_path(@material), :text => 'Delete', :count => 1
  end

  test 'show action buttons when admin' do
    sign_in users(:admin)
    get :show, :id => @material
    assert_select 'a.btn-primary[href=?]', edit_material_path(@material), :count => 1
    assert_select 'a.btn-danger[href=?]', material_path(@material), :text => 'Delete', :count => 1
  end

  #API Actions
  test 'should find existing material by title and content provider' do
    post 'check_exists', :format => :json, :material => { title: @material.title,
                                                          url: 'whatever.com',
                                                          content_provider_id: @material.content_provider_id }
    assert_response :success
    assert_equal(JSON.parse(response.body)['id'], @material.id)
  end

  test 'should find existing material by url' do
    post 'check_exists', :format => :json, :material => { title: 'whatever',
                                                          url: @material.url,
                                                          content_provider_id: @material.content_provider_id }
    assert_response :success
    assert_equal(JSON.parse(response.body)['id'], @material.id)
  end

  test 'should return nothing when material does not exist' do
    post 'check_exists', :format => :json, :material => { :url => 'http://no-such-url.com' }
    assert_response :success
    assert_equal '{}', response.body
  end

  test 'should render properly when no url supplied' do
    post 'check_exists', :format => :json, :material => { :url => nil }
    assert_response :success
    assert_equal '{}', response.body
  end

  test 'should display filters on index' do
    get :index
    assert_select 'h4.nav-heading', :text => /Content provider/, :count => 0
    assert_select 'div.list-group-item', :count => Material.count
  end

  test 'should create new material through API' do
    scraper_role = Role.fetch('scraper_user')
    scraper_user = User.where(:role_id => scraper_role.id).first
    material_title = 'horse'
    assert scraper_user
    assert_difference('Material.count') do
      post 'create', {user_token: scraper_user.authentication_token,
                      user_email: scraper_user.email,
                      material: {
                          title: material_title,
                          url: 'http://horse.com',
                          long_description: 'I love horses',
                          short_description: 'Best of all the animals'
                      },
                      :format => 'json'}
    end
    assert_equal material_title, JSON.parse(response.body)['title']
  end

  test 'should not create new material without valid authentication token' do
    scraper_role = Role.fetch('scraper_user')
    scraper_user = User.where(:role_id => scraper_role.id).first
    assert scraper_user

    assert_no_difference('Material.count') do
      post 'create', {user_token: 'made up authentication token',
                      user_email: scraper_user.email,
                      material: {
                          title: 'material_title',
                          url: 'http://horse.com',
                          short_description: 'All about horses'
                      },
                      :format => 'json'}
    end
    assert_response 401
  end

  test 'should update existing material through API' do
    user = users(:scraper_user)
    material = materials(:scraper_user_material)

    new_title = "totally new title"
    assert_no_difference('Material.count') do
      post 'update', {user_token: user.authentication_token,
                      user_email: user.email,
                      material: {
                          title: new_title,
                          url: material.url,
                          short_description: material.short_description
                      },
                      :id => material.id,
                      :format => 'json'}
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
      post 'update', {user_token: other_user.authentication_token,
                      user_email: other_user.email,
                      material: {
                          title: new_title,
                          url: material.url,
                          short_description: material.short_description
                      },
                      :id => material.id,
                      :format => 'json'}
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
      post 'update_packages', { id: @material.id,
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
        post 'update_packages', { id: @material.id,
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
      patch :update, id: @material, material: {
          title: 'New title',
          short_description: 'New description',
          url: 'http://new.url.com',
          content_provider_id: ContentProvider.first.id,
          external_resources_attributes: { "1" => { title: 'Cool link', url: 'https://tess.elixir-uk.org/', _destroy: '0' } }
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
    sign_in material.user

    assert_difference('ExternalResource.count', -1) do
      patch :update, id: material, material: {
          title: 'New title',
          short_description: 'New description',
          url: 'http://new.url.com',
          content_provider_id: ContentProvider.first.id,
          external_resources_attributes: { "0" => { id: resource.id, _destroy: '1' } }
      }
    end

    assert_redirected_to material_path(assigns(:material))
    assert_equal 1, assigns(:material).external_resources.count
  end

  test 'should modify external resource from material' do
    material = materials(:material_with_external_resource)
    resource = material.external_resources.first
    sign_in material.user

    assert_no_difference('ExternalResource.count') do
      patch :update, id: material, material: {
          title: 'New title',
          short_description: 'New description',
          url: 'http://new.url.com',
          content_provider_id: ContentProvider.first.id,
          external_resources_attributes: { "1" => { id: resource.id, title: 'Cool link',
                                                    url: 'http://www.reddit.com', _destroy: '0' } }
      }
    end

    assert_redirected_to material_path(assigns(:material))
    resource = assigns(:material).external_resources.first
    assert_equal 'Cool link', resource.title
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
      post :create, material: { short_description: '<b>hi</b><script>alert("hi!");</script>',
                                long_description: '<b>hi</b><script>alert("hi!");</script>',
                                title: 'Insanity',
                                url: 'http://www.example.com/sanity/0' }
    end

    assert_redirected_to material_path(assigns(:material))
    assert_equal 'hi', assigns(:material).short_description
    assert_equal 'hi', assigns(:material).long_description
  end

  test 'should log parameter changes when updating a material' do
    sign_in @material.user
    @material.activities.destroy_all

    # 5 = 4 for parameters + 1 for update
    assert_difference('PublicActivity::Activity.count', 5) do
      patch :update, id: @material, material: @updated_material
    end

    assert_equal 1, @material.activities.where(key: 'material.update').count
    assert_equal 4, @material.activities.where(key: 'material.update_parameter').count

    parameters = @material.activities.where(key: 'material.update_parameter').map(&:parameters)
    title_activity = parameters.detect { |p| p[:attr] == 'title' }
    url_activity = parameters.detect { |p| p[:attr] == 'url' }
    description_activity = parameters.detect { |p| p[:attr] == 'short_description' }
    content_provider_activity = parameters.detect { |p| p[:attr] == 'content_provider_id' }

    assert_equal 'New title', title_activity[:new_val]
    assert_equal 'http://new.url.com', url_activity[:new_val]
    assert_equal 'New description', description_activity[:new_val]
    assert_equal ContentProvider.first.id, content_provider_activity[:new_val]
    assert_equal ContentProvider.first.title, content_provider_activity[:association_name]

    old_controller = @controller
    @controller = ActivitiesController.new

    xhr :get, :index, material_id: @material, xhr: true

    assert_select '.activity', count: 6 # +1 because they are wrapped in a .activity div for some reason...

    @controller = old_controller
  end

  test 'parameter log activity works when removing an association' do
    sign_in @material.user
    @material.activities.destroy_all

    assert_difference('PublicActivity::Activity.count', 2) do  # 2 = 1 for parameters + 1 for update
      patch :update, id: @material, material: { content_provider_id: nil }
    end

    assert_equal 1, @material.activities.where(key: 'material.update').count
    assert_equal 1, @material.activities.where(key: 'material.update_parameter').count

    parameters = @material.activities.where(key: 'material.update_parameter').map(&:parameters)
    content_provider_activity = parameters.detect { |p| p[:attr] == 'content_provider_id' }

    assert content_provider_activity[:new_val].blank?
    assert content_provider_activity[:association_name].blank?

    old_controller = @controller
    @controller = ActivitiesController.new

    xhr :get, :index, material_id: @material

    assert_select '.activity', count: 3 # +1 because they are wrapped in a .activity div for some reason...

    @controller = old_controller
  end

  test 'should not log an update when only boring fields have changed' do
    sign_in @material.user
    @material.activities.destroy_all

    assert_no_difference('PublicActivity::Activity.count') do
      patch :update, id: @material, material: { last_scraped: Time.now }
    end
  end

  test 'can assign nodes by name' do
    sign_in users(:regular_user)

    assert_difference('Material.count') do
      post :create, material: { short_description: @material.short_description,
                                title: @material.title,
                                url: @material.url,
                                node_names: [nodes(:westeros).name, nodes(:good).name]
      }
    end
    assert_redirected_to material_path(assigns(:material))

    assert_includes assigns(:material).node_ids, nodes(:westeros).id
    assert_includes assigns(:material).node_ids, nodes(:good).id
  end

  test 'can lock fields' do
    sign_in @material.user
    assert_difference('FieldLock.count', 2) do
      patch :update, id: @material, material: { title: 'hi', locked_fields: ['title', 'short_description'] }
    end

    assert_redirected_to material_path(assigns(:material))
    assert_equal 2, assigns(:material).locked_fields.count
    assert assigns(:material).field_locked?(:title)
    assert assigns(:material).field_locked?(:short_description)
    refute assigns(:material).field_locked?(:url)
  end

  test 'scraper cannot overwrite locked fields' do
    user = users(:scraper_user)
    material = materials(:scraper_user_material)
    material.locked_fields = [:title]
    material.save!

    assert_no_difference('Material.count') do
      post 'update', {user_token: user.authentication_token,
                      user_email: user.email,
                      material: {
                          title: 'new title',
                          url: material.url,
                          short_description: 'new description'
                      },
                      id: material.id,
                      format: 'json'}
    end

    parsed_response = JSON.parse(response.body)
    assert_equal material.title, parsed_response['title'], 'Title should not have changed'
    assert_equal 'new description', parsed_response['short_description']
  end

  test 'normal user can overwrite locked fields' do
    @material.locked_fields = [:title]
    @material.save!

    sign_in @material.user
    patch :update, id: @material, material: { title: 'new title' }
    assert_redirected_to material_path(assigns(:material))

    assert_equal 'new title', assigns(:material).title
  end

  test 'should count index results' do
    begin
      TeSS::Config.solr_enabled = true

      materials = Material.all

      Material.stub(:search_and_filter, MockSearch.new(materials)) do
        get :count, format: :json
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
        get :count, q: 'test', keywords: 'dolphins', blabla: 'booboo', format: :json
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
    suggestion.scientific_topic_names = ['Genomics']
    suggestion.save!

    assert_difference('EditSuggestion.count', -1) do
      post :add_topic, id: @material.id, topic: 'Genomics'
    end

    assert_response :success

    assert_equal ['Genomics'], @material.reload.scientific_topic_names
    assert_nil @material.reload.edit_suggestion
  end

  test 'should reject topic for curator' do
    sign_in users(:curator)

    assert_empty @material.scientific_topic_names

    suggestion = @material.build_edit_suggestion
    suggestion.scientific_topic_names = ['Genomics']
    suggestion.save!

    assert_difference('EditSuggestion.count', -1) do
      post :reject_topic, id: @material.id, topic: 'Genomics'
    end

    assert_response :success

    assert_empty @material.reload.scientific_topic_names
    assert_nil @material.reload.edit_suggestion
  end

  test 'should not approve topic for unprivileged user' do
    sign_in users(:another_regular_user)

    assert_empty @material.scientific_topic_names

    suggestion = @material.build_edit_suggestion
    suggestion.scientific_topic_names = ['Genomics']
    suggestion.save!

    assert_no_difference('EditSuggestion.count') do
      post :add_topic, id: @material.id, topic: 'Genomics'
    end

    assert_response :forbidden

    assert_empty @material.reload.scientific_topic_names
    assert_equal ['Genomics'], @material.reload.edit_suggestion.scientific_topic_names
  end

  test 'should not reject topic for unprivileged user' do
    sign_in users(:another_regular_user)

    assert_empty @material.scientific_topic_names

    suggestion = @material.build_edit_suggestion
    suggestion.scientific_topic_names = ['Genomics']
    suggestion.save!

    assert_no_difference('EditSuggestion.count') do
      post :reject_topic, id: @material.id, topic: 'Genomics'
    end

    assert_response :forbidden

    assert_empty @material.reload.scientific_topic_names
    assert_equal ['Genomics'], @material.reload.edit_suggestion.scientific_topic_names
  end

  test 'should remove edit suggestion after update' do
    sign_in @user

    assert_difference('EditSuggestion.count', -1) do
      patch :update, id: @material_with_suggestions, material: @updated_material_with_suggestions
    end
  end
end
