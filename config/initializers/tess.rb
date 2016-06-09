# http://stackoverflow.com/a/735130
Dir[File.join(Rails.root, 'lib', 'tess', '*.rb')].each do |file|
  require file
end
