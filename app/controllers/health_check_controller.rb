class HealthCheckController < ActionController::Base # :nodoc:
  rescue_from(Exception) { render_down }

  def show
    render_up
  end

  private
  def render_up
    render plain: 'up', status: 200
  end

  def render_down
    render plain: 'down', status: 503
  end
end
