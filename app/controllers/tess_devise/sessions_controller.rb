class TessDevise::SessionsController < Devise::SessionsController

  def create
    clear_legacy_cookie

    super
  end

  def destroy
    super

    clear_legacy_cookie
  end

  private

  def clear_legacy_cookie
    # Clean up legacy host-only session cookie
    key = Rails.application.config.session_options[:key]
    append_set_cookie("#{key}=; path=/; Max-Age=0; HttpOnly; SameSite=Lax")
  end

  def append_set_cookie(value)
    existing = response.headers['Set-Cookie']

    case existing
    when nil
      response.headers['Set-Cookie'] = value
    when String
      response.headers['Set-Cookie'] = [existing, value]
    when Array
      existing << value
    end
  end
end