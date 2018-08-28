module IdentifiersDotOrg
  extend ActiveSupport::Concern

  class_methods do
    # Use the (lowercase) first letter of the class name to determine the key. Override this if needed.
    def identifiers_dot_org_key
      name[0].downcase
    end
  end

  def identifiers_dot_org_id
    "#{TeSS::Config.identifiers_prefix}:#{self.class.identifiers_dot_org_key}#{self.id}"
  end

  def identifiers_dot_org_url
    "#{TeSS::Config.identifiers_url}#{identifiers_dot_org_id}"
  end
end
