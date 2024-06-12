require 'test_helper'

class IdentifierResolutionTest < ActionDispatch::IntegrationTest

  test 'resolve event' do
    event = events(:one)

    get "/resolve/e#{event.id}"

    assert_redirected_to event_path(event.id)

    follow_redirect!

    assert_equal 'text/html; charset=utf-8', response.content_type
  end

  test 'resolve material' do
    material = materials(:good_material)

    get "/resolve/m#{material.id}"

    assert_redirected_to material_path(material.id)
  end

  test 'resolve content provider' do
    content_provider = content_providers(:goblet)

    get "/resolve/p#{content_provider.id}"

    assert_redirected_to content_provider_path(content_provider.id)
  end

  test 'resolve workflow' do
    workflow = workflows(:two)

    get "/resolve/w#{workflow.id}"

    assert_redirected_to workflow_path(workflow.id)
  end

  test 'ignores prefix when resolving' do
    material = materials(:good_material)

    get "/resolve/tess:m#{material.id}"

    assert_redirected_to material_path(material.id)

    get "/resolve/batman:m#{material.id}"

    assert_redirected_to material_path(material.id)
  end

  test 'does not resolve bad identifier' do
    event = events(:one)

    get "/resolve/x#{event.id}"

    assert_response :bad_request

    assert_select '#error-message', text: /Unrecognized type/
  end

  test 'handles parse error' do
    assert_raises(ActionController::RoutingError) do
      get "/resolve/hell:::::o:::wor:::l:::d"
    end
  end

  test 'does not resolve missing resource' do
    event = events(:one)

    event.destroy!

    get "/resolve/e#{event.id}"

    follow_redirect!

    assert_response :not_found
  end
end
