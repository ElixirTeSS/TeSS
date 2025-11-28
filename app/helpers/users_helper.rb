# The helper for Workflow classes
module UsersHelper

  def self.user_profile_resource_limit
    30
  end

  def orcid_link(profile, *opts)
    content_tag(:span) do
      if profile.orcid_authenticated?
        concat image_tag('ORCID-iD_icon_vector.svg', size: 16)
        concat ' '
        concat external_link(profile.orcid, profile.orcid_url, *opts)
      else profile.orcid.present?
        concat image_tag('ORCID-iD_icon_unauth_vector.svg', size: 16)
        concat ' '
        concat external_link(profile.orcid, profile.orcid_url, *opts)
        concat ' (Unauthenticated)'
      end
    end
  end

end
