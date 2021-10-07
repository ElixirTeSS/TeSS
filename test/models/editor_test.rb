require 'test_helper'

class EditorTest < ActiveSupport::TestCase

  setup do
    mock_images
  end

  test 'can create and delete editors' do
    user = users(:another_regular_user)
    prov = content_providers(:goblet)

    # check empty list
    assert prov.editors
    assert_equal 0, prov.editors.size

    # add user
    prov.add_editor user
    prov.save!

    # check list of editors
    assert prov.editors
    assert_equal 1, prov.editors.size
    assert_equal 'Dale', prov.editors.first.username

    # check list or providers
    assert user.providers
    assert_equal 1, prov.editors.size
    assert_equal 'This is the goblet test description', user.providers.first.description

    # add another couple
    prov.add_editor users(:trainer_user)
    prov.add_editor users(:private_user)
    prov.save!
    assert_equal 3, prov.editors.size

    # remove an editor
    prov.remove_editor users(:trainer_user)
    prov.save!
    assert_equal 2, prov.editors.size
    assert_equal 'StevieN', prov.editors[1].username
  end

  test 'can can only add the same user once' do
    user = users(:another_regular_user)
    prov = content_providers(:goblet)

    # check empty list
    assert prov.editors
    assert_equal 0, prov.editors.size

    # add user
    prov.add_editor user
    prov.save!

    # check list of editors
    assert prov.editors
    assert_equal 1, prov.editors.size
    assert_equal 'Dale', prov.editors.first.username


    # try to add the same user
    prov.add_editor users(:another_regular_user)
    prov.save!
    assert_equal 1, prov.editors.size
  end




end