# The helper for Workflow classes
module WorkflowsHelper
  WORKFLOWS_INFO = I18n.t('info.workflows.description').freeze

  def workflows_info
    format(WORKFLOWS_INFO, site_name: TeSS::Config.site['title_short'])
  end
end
