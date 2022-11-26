module SourcesHelper
  SOURCES_INFO = "#{TeSS::Config.site['title_short']} provides a facility" +
    " to automatically ingest events and materials from a variety of sources.".freeze

  def grouped_ingestor_options_for_select
    opts = []

    Ingestors::IngestorFactory.grouped_options.each do |category, configs|
        category_options = configs.map do |c|
          [c[:title], c[:key], ''] if current_user&.is_admin? || TeSS::Config.user_ingestion_methods&.include?(c[:key].to_s)
        end.compact
        opts << [t("ingestion.categories.#{category}"), category_options] if category_options.any?
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

  def user_creatable_ingestion_methods
    return [] unless TeSS::Config.feature['sources'] &&
      TeSS::Config.feature['user_source_creation'] &&
      TeSS::Config.user_ingestion_methods&.any?

    TeSS::Config.user_ingestion_methods.map do |key|
      Ingestors::IngestorFactory.fetch_ingestor_config(key)[:title]
    end
  end
end
