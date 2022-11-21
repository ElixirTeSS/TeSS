module SourcesHelper
  SOURCES_INFO = "#{TeSS::Config.site['title_short']} provides a facility" +
    " to ingest events and materials using automated sources.".freeze

  def grouped_ingestor_options_for_select
    opts = []

    Ingestors::IngestorFactory.grouped_options.each do |category, configs|
      opts << [t("ingestion.categories.#{category}"), configs.map { |c| [c[:title], c[:key], ''] }]
    end

    opts.sort_by { |o| o[0] }
  end

  def approval_options_for_select
    Source::APPROVAL_STATUS.values.map { |status| [t("sources.approval_status.#{status}"), status] }
  end

  def source_enabled_badge(enabled)
    content_tag(:span, enabled ? 'Enabled' : 'Disabled', class: "label label-#{enabled ? 'success' : 'danger'}")
  end

  def source_approval_badge(status)
    case status
    when :not_approved
      content_tag(:span, t("sources.approval_status.#{status}"), class: 'label label-danger')
    when :requested
      content_tag(:span, t("sources.approval_status.#{status}"), class: 'label label-warning')
    when :approved
      content_tag(:span, t("sources.approval_status.#{status}"), class: 'label label-success')
    end
  end
end
