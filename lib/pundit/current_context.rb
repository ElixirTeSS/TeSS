# frozen_string_literal: true

module Pundit
  class CurrentContext
    attr_reader :user, :request

    def initialize(user, request)
      @user = user
      @request = request
    end
  end
end
