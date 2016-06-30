require 'test_helper'

class WorkflowTest < ActiveSupport::TestCase

  test "can create workflow" do
    workflow = Workflow.new(title: 'hello world')

    assert workflow.save
  end

  test "can't create workflow without title" do
    workflow = Workflow.new

    refute workflow.save
    assert_not_empty workflow.errors
  end

end
