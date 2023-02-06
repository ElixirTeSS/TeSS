require 'sprockets/processing'
extend Sprockets::Processing

Sprockets.register_preprocessor 'image/svg+xml', SvgRecolourer
