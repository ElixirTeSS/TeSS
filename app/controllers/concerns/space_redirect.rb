module SpaceRedirect
  extend ActiveSupport::Concern

  private

  def redirect_to_space(path, space)
    if space&.is_subdomain?
      port_part = ''
      port_part = ":#{request.port}" if (request.protocol == "http://" && request.port != 80) ||
        (request.protocol == "https://" && request.port != 443)
      redirect_to URI.join("#{request.protocol}#{space.host}#{port_part}", path).to_s, allow_other_host: true
    else
      redirect_to path
    end
  end
end
