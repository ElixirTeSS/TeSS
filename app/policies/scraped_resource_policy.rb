# A policy specific to things that have been scraped. Events and Materials

class ScrapedResourcePolicy < ResourcePolicy

  def manage?
    super || (@user && @user.is_curator?) || is_content_provider_editor?
  end

  private

  def is_content_provider_editor?
    provider = nil
    provider = @record if @record.is_a?(ContentProvider)
    provider ||= @record.content_provider if @record.respond_to?(:content_provider)

    (@user && provider && (provider.user == @user || provider.editors.include?(@user)))
  end

end
