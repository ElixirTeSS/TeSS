module Bioschemas
  class DataDump
    attr_reader :name

    def initialize(model, space: Space.current_space, name: nil, records: nil)
      @name = name || model.model_name.plural
      @space = space
      Space.with_current_space(space) do
        @records = records || model.in_current_space.from_verified_users
      end
    end

    def file
      File.open(file_path, 'r')
    end

    def write
      FileUtils.mkdir_p(self.class.file_path_base)
      File.atomic_write(file_path) do |f|
        f.write("[\n")
        first = true
        # Write each record at a time to avoid loading entire set into memory
        bioschemas do |record|
          f.write(",\n") unless first
          record.to_json.each_line do |line|
            f.write('  ', line) # Indent 2 spaces
          end
          first = false
        end
        f.write("\n]")
      end
    end

    def bioschemas
      if block_given?
        @records.each do |record|
          yield record.to_bioschemas.first
        end
      else
        @records.each.map { |record| record.to_bioschemas.first }
      end
    end

    def file_name
      "#{@space&.default? ? '' : "space-#{@space.id}-"}#{@name}-bioschemas-dump.jsonld"
    end

    def exists?
      File.exist?(file_path)
    end

    def size
      File.size(file_path) if exists?
    end

    def date_modified
      File.mtime(file_path) if exists?
    end

    def self.generate_dumps
      generate_dumps_for_space(Space.default)

      if TeSS::Config.feature['spaces']
        Space.find_each do |space|
          generate_dumps_for_space(space)
        end
      end
    end

    def self.generate_dumps_for_space(space)
      [Material, Event].map do |model|
        generate_dump(model, space)
      end
    end

    def self.generate_dump(model, space)
      dump = new(model, space: space)
      dump.write
      dump
    end

    private

    def file_path
      File.join(self.class.file_path_base, file_name)
    end

    def self.file_path_base
      Rails.root.join('public', 'bioschemas_dumps')
    end
  end
end
