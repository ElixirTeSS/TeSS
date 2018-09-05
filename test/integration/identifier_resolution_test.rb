require 'test_helper'

class IdentifierResolutionTest < ActionDispatch::IntegrationTest

  test 'resolve event' do
    event = events(:one)

    get "/resolve/e#{event.id}"

    assert_redirected_to event

    follow_redirect!

    assert_equal 'text/html', response.content_type
  end

  test 'resolve material' do
    material = materials(:good_material)

    get "/resolve/m#{material.id}"

    assert_redirected_to material
  end

  test 'resolve content provider' do
    content_provider = content_providers(:goblet)

    get "/resolve/p#{content_provider.id}"

    assert_redirected_to content_provider
  end

  test 'resolve workflow' do
    workflow = workflows(:two)

    get "/resolve/w#{workflow.id}"

    assert_redirected_to workflow
  end

  test 'ignores prefix when resolving' do
    material = materials(:good_material)

    get "/resolve/tess:m#{material.id}"

    assert_redirected_to material

    get "/resolve/batman:m#{material.id}"

    assert_redirected_to material
  end

  test 'does not resolve bad identifier' do
    event = events(:one)

    get "/resolve/x#{event.id}"

    assert_response :bad_request

    assert_select '#flash-container .alert', /Unrecognized type/
  end

  test 'does not resolve missing resource' do
    event = events(:one)

    event.destroy!

    assert_raises(ActiveRecord::RecordNotFound) do
      get "/resolve/e#{event.id}"

      follow_redirect!
    end
  end
end
