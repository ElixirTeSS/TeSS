require 'test_helper'

class NodesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
    @node = nodes(:good)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_includes assigns(:nodes), @node
  end

  test "should get new" do
    sign_in users(:admin)

    get :new
    assert_response :success
  end

  test "should create node" do
    sign_in users(:admin)

    assert_difference('Node.count') do
      assert_difference('StaffMember.count') do
        post :create, node: { carousel_images: '', country_code: 'FN',
                              home_page: 'http://www.example.com', #institutions: '',
                              member_status: 'Member', name: 'Finnland',
                              twitter: '@finnlandnode', staff_attributes:
                                  {
                                      "948593" => { name: 'Finn',
                                                    email: 'f@example.com',
                                                    role: 'Training coordinator',
                                                    image_url: 'http://example.com/images/gorgeouspic.png',
                                                    _destroy: '0'  }
                                  }
        }
      end
    end

    assert_redirected_to node_path(assigns(:node))
  end

  test "should show node" do
    get :show, id: @node
    assert_response :success
  end

  test "should get edit" do
    sign_in users(:admin)

    get :edit, id: @node
    assert_response :success
  end

  test "should update node" do
    sign_in users(:admin)

    patch :update, id: @node, node: { carousel_images: @node.carousel_images, country_code: ':)',
                                      home_page: @node.home_page, #institutions: @node.institutions,
                                      member_status: @node.member_status, name: @node.name,
                                      twitter: @node.twitter }
    assert_redirected_to node_path(assigns(:node))
    assert_equal ':)', assigns(:node).country_code
  end

  test "should create node staff via edit form" do
    sign_in users(:admin)

    assert_difference('StaffMember.count', 1) do
      patch :update, id: @node, node: { carousel_images: @node.carousel_images, country_code: @node.country_code,
                                        home_page: @node.home_page, #institutions: @node.institutions,
                                        member_status: @node.member_status, name: @node.name,
                                        twitter: @node.twitter, staff_attributes:
                                            {
                                                "0" => @node.staff[0].attributes.merge(_destroy: '0' ),
                                                "1" => @node.staff[1].attributes.merge(_destroy: '0' ),
                                                "1256161262" => { name: 'New Staff Member',
                                                                  email: 'nsm@example.com',
                                                                  role: 'Training coordinator',
                                                                  image_url: 'http://example.com/images/newb.png',
                                                                  _destroy: '0'  },
                                            }
      }
    end
    assert_redirected_to node_path(assigns(:node))
    assert_equal 3, assigns(:node).staff.count
  end

  test "should delete node staff via edit form" do
    sign_in users(:admin)

    assert_difference('StaffMember.count', -1) do
      patch :update, id: @node, node: { carousel_images: @node.carousel_images, country_code: @node.country_code,
                                        home_page: @node.home_page, #institutions: @node.institutions,
                                        member_status: @node.member_status, name: @node.name,
                                        twitter: @node.twitter, staff_attributes:
                                            {
                                                "0" => @node.staff[0].attributes.merge(_destroy: '0' ),
                                                "1" => @node.staff[1].attributes.merge(_destroy: '1' ),
                                            }
      }
    end
    assert_redirected_to node_path(assigns(:node))
    assert_equal 1, assigns(:node).staff.count
  end

  test "should edit node staff via edit form" do
    sign_in users(:admin)

    patch :update, id: @node, node: { carousel_images: @node.carousel_images, country_code: @node.country_code,
                                      home_page: @node.home_page, #institutions: @node.institutions,
                                      member_status: @node.member_status, name: @node.name,
                                      twitter: @node.twitter, staff_attributes:
                                          {
                                              "0" => @node.staff[0].attributes.merge(_destroy: '0' ),
                                              "1" => @node.staff[1].attributes.merge(_destroy: '0',
                                                                                     name: 'Updated name',
                                                                                     email: 'u@example.com',
                                                                                     role: 'Nobody'),
                                          }
    }

    assert_redirected_to node_path(assigns(:node))
    updated_staff = assigns(:node).staff.detect { |s| s.name == 'Updated name' }
    assert_not_nil updated_staff
    assert_equal 'u@example.com', updated_staff.email
    assert_equal 'Nobody', updated_staff.role
  end

  test "should destroy node" do
    sign_in users(:admin)

    assert_difference('Node.count', -1) do
      delete :destroy, id: @node
    end

    assert_redirected_to nodes_path
  end
end
