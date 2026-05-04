module Renderers
  class Zenodo
    VALID_HOSTS = %w[zenodo.org doi.org].freeze
    VALID_SCHEMES = %w[http https].freeze
    TEMPLATE = %(<video controls height="315" style="display:none;" id="zenodo-video"></video><script>make_zenodo_video(document.getElementById('zenodo-video'), '%{files_url}');</script>)

    def initialize(resource)
      @resource = resource
    end

    def can_render?
      @resource.url && construct_files_url(@resource.url)
    end

    def render_content
      files_url = construct_files_url(@resource.url)
      (TEMPLATE % { files_url: files_url }).html_safe
    end

    def extract_record_id(url)
      parsed_url = URI.parse(url)
      return unless VALID_SCHEMES.include?(parsed_url.scheme)

      match = parsed_url.host == 'zenodo.org' && url.match(/records\/(\d+)/) ||
        parsed_url.host == 'doi.org' && url.match(/10\.5281\/zenodo\.(\d+)/)
      match[1] if match
    rescue
      nil
    end

    def construct_files_url(url)
      record_id = extract_record_id(url)
      "https://zenodo.org/api/records/#{record_id}/files" if record_id
    end
  end
end