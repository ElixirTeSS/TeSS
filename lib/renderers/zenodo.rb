module Renderers
  class Zenodo
    VALID_SCHEMES = %w[http https].freeze

    def initialize(resource)
      @url = resource.url
      @parsed_url = begin
        Addressable::URI.parse(@url)
      rescue StandardError
        nil
      end
    end

    def can_render?
      @url && @parsed_url && zenodo_id && VALID_SCHEMES.include?(@parsed_url.scheme)
    end

    def render_content
      files_url = "https://zenodo.org/api/records/#{zenodo_id}/files"
      key = @parsed_url.query_values.to_h['preview_file']
      ActionController::Base.helpers.content_tag(
        :video, '',
        controls: true, height: 500, style: 'display:none;', id: 'zenodo-video',
        data: { zenodo_files_url: files_url, zenodo_preferred_key: key }
      )
    end

    private

    def zenodo_id
      match = @parsed_url.host == 'zenodo.org' && @url.match(%r{records/(\d+)}) ||
              @parsed_url.host == 'doi.org' && @url.match(%r{10\.5281/zenodo\.(\d+)})
      match[1] if match
    end
  end
end
