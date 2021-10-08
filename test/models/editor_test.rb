require 'test_helper'

class EditorTest < ActiveSupport::TestCase

  setup do
    mock_images
  end

  test 'can create and delete editors' do
    user = users :another_regular_user
    prov = content_providers(:goblet)

    # check empty list
    assert prov.editors
    assert_equal 0, prov.editors.size

    # add user
    prov.add_editor user

    # check list of editors
    assert prov.editors
    assert_equal 1, prov.editors.size
    assert_equal 'Dale', prov.editors.first.username

    # check list or providers
    assert user.editables
    assert_equal 1, prov.editors.size
    assert_equal 'This is the goblet test description', user.editables.first.description

    # add another couple
    prov.add_editor users(:trainer_user)
    prov.add_editor users(:private_user)
    assert_equal 3, prov.editors.size

    # remove an editor
    prov.remove_editor users(:trainer_user)
    assert_equal 2, prov.editors.size
    assert_equal 'StevieN', prov.editors[1].username
  end

  test 'can can only add the same user once' do
    user = users :another_regular_user
    prov = content_providers(:goblet)

    # check empty list
    assert prov.editors
    assert_equal 0, prov.editors.size

    # add user
    prov.add_editor user

    # check list of editors
    assert prov.editors
    assert_equal 1, prov.editors.size
    assert_equal 'Dale', prov.editors.first.username

    # try to add the same user
    prov.add_editor users(:another_regular_user)
    assert_equal 1, prov.editors.size
  end

  test 'cannot add the owner' do
    regular = users :regular_user
    trainer = users :trainer_user
    prov = content_providers :organisation_provider

    # check empty list
    assert prov.editors
    assert_equal 0, prov.editors.size

    # add user
    prov.add_editor regular

    # check list of editors
    assert prov.editors
    assert_equal 0, prov.editors.size

    # add user
    prov.add_editor trainer

    # check list of editors
    assert prov.editors
    assert_equal 1, prov.editors.size
    assert_equal trainer.username, prov.editors.first.username
  end

  test 'can list editable providers for a user' do
    trainer = users :trainer_user
    prov1 = content_providers :organisation_provider
    prov2 = content_providers :goblet

    #check empty list
    assert trainer.editables
    assert_equal 0, trainer.editables.size

    # add to providers
    prov1.add_editor trainer
    assert_equal 1, prov1.editors.size

    prov2.add_editor trainer
    assert_equal 1, prov2.editors.size

    # check user's references to providers
    assert trainer.editables
    trainer.editables.reload
    assert_equal 2, trainer.editables.size
    assert_equal prov2.title, trainer.editables.last.title

  end

end