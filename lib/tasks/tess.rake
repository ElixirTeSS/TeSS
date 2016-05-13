namespace :tess do

  desc "Populates the database with Node information from a JSON document"
  task load_node_json: :environment do
    path = File.join(Rails.root, 'config', 'data', 'elixir_nodes.json')

    raise "Couldn't find Node data at #{path}" unless File.exist?(path)

    hash = JSON.parse(File.read(path))
    nodes = Node.load_from_hash(hash, verbose: true)

    puts "#{nodes.select(&:valid?).count}/#{nodes.count} succeeded"
    puts "Done"
  end

end
