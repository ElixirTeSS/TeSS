# A policy specific to things that have been scraped. Events and Materials

class ScrapedResourcePolicy < ResourcePolicy

  def manage?
    super || (@user&.is_curator?) || is_content_provider_editor?
  end

  def shown?
    return true if @space == nil
    if @space == Space.current_space
      user_groups  = @user.groups.pluck(:id)
      space_groups = @space.groups.pluck(:id)

      if @user && space_groups.all? { |group_id| user_groups.include?(group_id) }
        return true
      end
    end

    return false
  end

  class Scope < Scope
    def resolve
      scope.select { |record| ScrapedResourcePolicy.new(context, record).shown? }
    end
  end


  private

  def is_content_provider_editor?
    provider = nil
    provider = @record if @record.is_a?(ContentProvider)
    provider ||= @record.content_provider if @record.respond_to?(:content_provider)

    (@user && provider && (provider.user == @user || provider.editors.include?(@user)))
  end

end
