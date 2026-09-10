module Ingestors
  module ProviderIngestion
    include AutoParsing

    def initialize
      @provider_cache = {}
    end

    def fetch_provider(provider)
      if provider.is_a?(Hash)
        c = ProvidersController.new
        c.params = { provider: provider }
        provider = OpenStruct.new(c.send(:provider_params))
      end
      provider = handle_auto_parsing(provider)
      provider = handle_controlled_vocabulary(provider)
      provider
    end

    

  end
end