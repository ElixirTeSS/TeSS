# frozen_string_literal: true

class FairsharingController < ApplicationController
  before_action :client

  respond_to :json

  def search
    @results = @client.search(**search_params.to_h.symbolize_keys)
    respond_with({ results: @results, next_page: @results.next_page, prev_page: @results.prev_page })
  end

  private

  def client
    @client = Fairsharing::Client.new
  end

  def search_params
    params.permit(:query, :page, :type)
  end
end
