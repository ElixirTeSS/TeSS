module HasFriendlyId
  extend ActiveSupport::Concern

  included do
    extend FriendlyId
    friendly_id :title, use: :slugged
    # Note: I had to include instance methods manually (rather than doing in the normal concern way)
    #  because FriendlyId does some insane metaprogramming that makes that not work for whatever reason...
    include InstanceMethods
  end

  module InstanceMethods
    def normalize_friendly_id(value)
      result = super(value)
      result =~ /\A\d+\Z/ ? SecureRandom.uuid : result
    end
  end
end