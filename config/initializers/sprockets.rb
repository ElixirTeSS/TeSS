require 'sprockets/processing'
extend Sprockets::Processing

Rails.application.reloader.to_prepare do
  Sprockets.register_preprocessor 'image/svg+xml', SvgRecolourer
end
