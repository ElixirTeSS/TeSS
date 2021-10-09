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
    assert_equal 2, trainer.editables.size
    assert_equal prov2.title, trainer.editables.last.title
  end

  test 'reassign resources on removal' do
    owner = users :regular_user
    trainer = users :trainer_user
    provider = content_providers :goblet
    event = events :training_event
    material = materials :training_material

    # check ownership
    assert owner
    assert trainer
    assert provider
    assert_equal owner, provider.user
    assert event
    assert_equal trainer, event.user
    assert_equal provider, event.content_provider
    assert material
    assert_equal trainer, material.user
    assert_equal provider, material.content_provider

    # check editors
    assert provider.editors
    provider.add_editor(trainer)
    assert provider.editors.include?(trainer),
           "trainer[#{trainer.username}] not found in provider[#{provider.title}].editors"
    assert trainer.editables.include?(provider),
           "trainer[#{trainer.username}] cannot edit provider[#{provider.title}]"

    # remove editor
    provider.remove_editor(trainer)
    assert !provider.editors.include?(trainer),
           "trainer[#{trainer.username}] still in provider[#{provider.title}].editors"
    assert !trainer.editables.include?(provider),
           "trainer[#{trainer.username}] can still edit provider[#{provider.title}]"

    # TODO: check reassignments

  end

end