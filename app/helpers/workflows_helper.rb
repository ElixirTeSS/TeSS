# frozen_string_literal: true

# The helper for Workflow classes
module WorkflowsHelper
  WORKFLOWS_INFO = "Training workflows in #{TeSS::Config.site['title_short']} are visual, step-by-step protocols that allow users to navigate materials in #{TeSS::Config.site['title_short']} in topic- or task-related ways.\n\n" \
                   'For example, they may encapsulate typical stages of particular kinds of data analysis (protein sequence analysis, structure analysis, etc.), where each stage/node in the workflow represents a given analysis step and links to the corresponding training resources.'.freeze
end
