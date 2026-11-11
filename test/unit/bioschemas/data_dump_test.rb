require 'test_helper'
require 'tmpdir'

class BioschemasDataDumpTest < ActiveSupport::TestCase
  setup do
    @dump_directory = Pathname.new(Dir.mktmpdir)
  end

  teardown do
    FileUtils.remove_entry(@dump_directory) if @dump_directory&.exist?
  end

  test 'writes a JSON-LD array and exposes file metadata' do
    material = materials(:good_material)
    dump = Bioschemas::DataDump.new(Material, records: [material])

    Bioschemas::DataDump.stub(:file_path_base, @dump_directory) do
      dump.write

      assert dump.exists?
      assert_operator dump.size, :>, 0
      assert_kind_of Time, dump.date_modified
      json = JSON.parse(material.to_bioschemas.first.to_json)
      json.delete('@context')
      assert_equal [json], JSON.parse(File.read(@dump_directory.join(dump.file_name)))['@graph']
    end
  end

  test 'uses distinct filenames for default and non-default spaces' do
    default_dump = Bioschemas::DataDump.new(Material, records: [])
    space = spaces(:plants)
    space_dump = Bioschemas::DataDump.new(Material, space: space, records: [])

    assert_equal 'materials-bioschemas-dump.jsonld', default_dump.file_name
    assert_equal "space-#{space.id}-materials-bioschemas-dump.jsonld", space_dump.file_name
  end

  test 'generates dumps for the default space and enabled spaces' do
    other_space = spaces(:plants)
    generated_spaces = []

    Bioschemas::DataDump.stub(:generate_dumps_for_space, ->(space) { generated_spaces << space }) do
      Space.stub(:find_each, ->(&block) { [other_space].each(&block) }) do
        with_settings(feature: { spaces: true }) do
          default_space = Space.default
          Bioschemas::DataDump.generate_dumps
          assert_equal [default_space, other_space], generated_spaces
        end
      end
    end
  end

  test 'does not generate space-specific dumps when spaces are disabled' do
    generated_spaces = []

    Bioschemas::DataDump.stub(:generate_dumps_for_space, ->(space) { generated_spaces << space }) do
      with_settings(feature: { spaces: false }) do
        default_space = Space.default
        Bioschemas::DataDump.generate_dumps
        assert_equal [default_space], generated_spaces
      end
    end
  end

  test 'generates material and event dumps for a space' do
    space = spaces(:plants)
    generated_models = []

    Bioschemas::DataDump.stub(:generate_dump, ->(model, dump_space) { generated_models << [model, dump_space] }) do
      Bioschemas::DataDump.generate_dumps_for_space(space)
    end

    assert_equal [[Material, space], [Event, space]], generated_models
  end

  test 'dumps contain only content for given space' do
    with_settings(feature: { spaces: true }) do
      space_material = materials(:plant_space_material)
      non_space_material = materials(:good_material)
      Material.where.not(id: [space_material, non_space_material]).destroy_all
      Event.destroy_all

      space = spaces(:plants)
      space_dump = Bioschemas::DataDump.new(Material, space: space)
      non_space_dump = Bioschemas::DataDump.new(Material)

      Bioschemas::DataDump.stub(:file_path_base, @dump_directory) do
        Bioschemas::DataDump.generate_dumps

        assert space_dump.exists?
        assert non_space_dump.exists?

        space_dump_titles = JSON.parse(space_dump.file.read)['@graph'].map { |r| r['name'] }
        non_space_dump_titles = JSON.parse(non_space_dump.file.read)['@graph'].map { |r| r['name'] }

        assert_equal 1, space_dump_titles.length
        assert_includes space_dump_titles, space_material.title

        assert_equal 1, non_space_dump_titles.length
        assert_includes non_space_dump_titles, non_space_material.title
      end
    end
  end
end
