module Renderers
  class Zenodo
    VALID_HOSTS = %w[zenodo.org doi.org].freeze
    VALID_SCHEMES = %w[http https].freeze
    TEMPLATE = %(<video controls height="500" style="display:none;" id="zenodo-video"></video><script>make_zenodo_video(document.getElementById('zenodo-video'), '%{files_url}', %{key});</script>)

    def initialize(resource)
      @resource = resource
    end

    def can_render?
      url && render_content.present?
    end

    def url
      @resource.url
    end

    def render_content
      parsed_url = Addressable::URI.parse(url)
      return unless VALID_SCHEMES.include?(parsed_url.scheme)

      match = parsed_url.host == 'zenodo.org' && url.match(/records\/(\d+)/) ||
        parsed_url.host == 'doi.org' && url.match(/10\.5281\/zenodo\.(\d+)/)
      return unless match

      files_url = "https://zenodo.org/api/records/#{match[1]}/files"
      key = parsed_url.query_values.to_h['preview_file']
      (TEMPLATE % { files_url: files_url, key: key.to_json }).html_safe
    rescue
      nil
    end
  end
end