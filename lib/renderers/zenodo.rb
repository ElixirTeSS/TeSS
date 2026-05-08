module Renderers
  class Zenodo
    VALID_SCHEMES = %w[http https].freeze
    TEMPLATE = %(<video controls height="500" style="display:none;" id="zenodo-video"></video><script>make_zenodo_video(document.getElementById('zenodo-video'), '%<files_url>s', %<key>s);</script>)

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
      format(TEMPLATE, files_url:, key: key.to_json).html_safe
    end

    private

    def zenodo_id
      match = @parsed_url.host == 'zenodo.org' && @url.match(%r{records/(\d+)}) ||
              @parsed_url.host == 'doi.org' && @url.match(%r{10\.5281/zenodo\.(\d+)})
      match[1] if match
    end
  end
end
