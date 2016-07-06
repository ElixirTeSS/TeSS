module WorkflowsHelper

  WORKFLOWS_INFO = "Training workflows in TeSS are visual, step-by-step protocols that allow users to navigate materials in TeSS in topic- or task-related ways.\n\n"+
      "For example, they may encapsulate typical stages of particular kinds of data analysis (protein sequence analysis, structure analysis, etc.), where each stage/node in the workflow represents a given analysis step and links to the corresponding training resources."

  # Convert Markdown descriptions of workflow nodes/edges to HTML and insert them into elements' data (passed in as JSON)
  def convertMarkdownDescriptionsIntoHTML(json)
    workflow = JSON.parse(json)
    wf_elements_to_change = workflow['nodes'] + workflow['edges']
    wf_elements_to_change.each do |element|
      description = element['data']['description']
      element['data']['html_description'] = render_markdown(description)
    end
    return workflow.to_json
  end


end
