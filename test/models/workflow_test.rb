require 'test_helper'

class WorkflowTest < ActiveSupport::TestCase

  setup do
    @wf1 = workflows(:one)
    @wf2 = workflows(:two)
  end

  test "can create workflow" do
    workflow = Workflow.new(title: 'hello world')

    assert workflow.save
  end

  test "can't create workflow without title" do
    workflow = Workflow.new

    refute workflow.save
    assert_not_empty workflow.errors
  end

  # instance_eval needed to test private methods
  test "check workflow content" do
    names = @wf2.instance_eval{ node_index('name')}
    descriptions = @wf2.instance_eval{ node_index('description')}
    assert_equal names.length, 2
    assert_equal names[0], 'Exciting stuff'
    assert_equal descriptions.length, 2
    assert_equal descriptions[0], 'This is very exciting indeed!'
  end

  test 'validates workflow CV fields' do
    w = @wf1

    w.difficulty_level = 'well ard'
    w.licence = 'to kill'
    refute w.save
    assert_equal 2, w.errors.count
    assert_equal ["must be a controlled vocabulary term"], w.errors[:difficulty_level]
    assert_equal ["must be a controlled vocabulary term"], w.errors[:licence]

    w.difficulty_level = 'intermediate'
    w.licence = 'BSD-3-Clause'
    assert w.save
    assert_equal 0, w.errors.count
  end

  test 'visibility scope' do
    assert_not_includes Workflow.visible_by(nil), workflows(:collaborated_workflow) # Guest
    assert_not_includes Workflow.visible_by(users(:non_collaborative_user)), workflows(:collaborated_workflow) # Non-owner user
    assert_includes Workflow.visible_by(users(:regular_user)), workflows(:collaborated_workflow) # Owner
    assert_includes Workflow.visible_by(users(:admin)), workflows(:collaborated_workflow) # Admin
    assert_includes Workflow.visible_by(users(:another_regular_user)), workflows(:collaborated_workflow) # Collaborator

    assert_includes Workflow.visible_by(nil), workflows(:one) # Guest
    assert_includes Workflow.visible_by(users(:non_collaborative_user)), workflows(:one) # Non-owner user
    assert_includes Workflow.visible_by(users(:regular_user)), workflows(:one) # Owner
    assert_includes Workflow.visible_by(users(:admin)), workflows(:one) # Admin
    assert_includes Workflow.visible_by(users(:another_regular_user)), workflows(:one) # Collaborator
  end

end
