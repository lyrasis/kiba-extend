# frozen_string_literal: true

module Helpers
  module_function

  def fixtures_dir
    app_dir = File.realpath(File.join(File.dirname(__FILE__), '..'))
    File.join(app_dir, 'spec', 'fixtures')
  end

  def populate_registry
    fkeypath = File.join(fixtures_dir, 'fkey.csv')
    entries = { fkey: { path: fkeypath, supplied: true, lookup_on: :id },
                invalid: {},
                fee: { path: fkeypath, lookup_on: :foo, supplied: true },
                foo: { path: fkeypath, creator: Helpers.method(:test_csv), tags: %i[test] },
                bar: { path: fkeypath, creator: Helpers.method(:lookup_csv), tags: %i[test report] },
                baz: { path: fkeypath, creator: Kiba::Extend::Utils::Lookup.method(:csv_to_hash), tags: %i[report] },
                warn: { path: fkeypath, dest_class: Kiba::Common::Destinations::CSV,
                        creator: Kiba::Extend.method(:csvopts),
                        dest_special_opts: { initial_headers: %i[objectnumber briefdescription] } } }
    entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
    Kiba::Extend.registry.namespace(:ns) do
      namespace(:sub) do
        register(:fkey, { path: 'data', supplied: true })
      end
    end
  end

  def transform_registry
    Kiba::Extend.registry.transform
  end

  def prepare_registry
    populate_registry
    transform_registry
  end

  def fake_creator_method
    FileUtils.touch(File.join(fixtures_dir, 'base_job_missing.csv'))
  end

  # for test in Kiba::Extend::Jobs::BaseJobsSpec that I can't get working
  # class BaseJob
  #   include Kiba::Extend::Jobs::Runner

  #   attr_reader :files
  #   def initialize(files:)
  #     @files = setup_files(files)
  #   end

  #   def creator=(arg)
  #     @creator = arg
  #   end

  #   def creator
  #     @creator
  #   end
  # end

  def test_csv
    File.join(File.expand_path(__dir__), 'tmp', 'test.csv')
  end

  def lookup_csv
    File.join(File.expand_path(__dir__), 'tmp', 'lkup.csv')
  end

  def generate_csv(rows)
    CSV.open(test_csv, 'w') do |csv|
      rows.each { |row| csv << row }
    end
  end

  def generate_lookup_csv(rows)
    CSV.open(lookup_csv, 'w') do |csv|
      rows.each { |row| csv << row }
    end
  end

  def execute_job(filename:, xform:, csvopt: {}, xformopt: {})
    output_rows = []
    settings = { filename: filename, csv_options: CSVOPT.merge(csvopt) }
    job = Kiba.parse do
      source Kiba::Common::Sources::CSV, settings
      transform(&:to_h)
      transform xform, xformopt
      transform { |row| output_rows << row }
    end

    Kiba.run(job)
    output_rows
  end

  def job_csv(filename:, incsvopt: {}, outcsvopt: {})
    insettings = { filename: filename, csv_options: CSVOPT.merge(incsvopt) }
    outsettings = { filename: filename, csv_options: CSVOPT.merge(outcsvopt) }
    job = Kiba.parse do
      source Kiba::Common::Sources::CSV, insettings
      transform(&:to_h)
      destination Kiba::Common::Destinations::CSV, outsettings
    end
    Kiba.run(job)

    output_rows = []
    job2 = Kiba.parse do
      source Kiba::Common::Sources::CSV, insettings
      transform(&:to_h)
      transform { |row| output_rows << row }
    end
    Kiba.run(job2)
    output_rows
  end
end
