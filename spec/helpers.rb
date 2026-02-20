# frozen_string_literal: true

require "kiba/extend"

module Helpers
  module_function

  def fixtures_dir = File.join(Bundler.root, "spec", "support", "fixtures")

  def tmp_dir = File.join(Bundler.root, "spec", "tmp")

  class TestJob
    include Kiba::Extend::Jobs::Parser

    attr_reader :control, :context, :accumulator
    def initialize(input:, accumulator:, transforms:)
      @accumulator = accumulator
      @control = Kiba.parse do
        source Kiba::Extend::Sources::Enumerable, input
        destination Kiba::Extend::Destinations::Lambda,
          on_write: ->(r) { accumulator << r }
      end
      @context = Kiba::Context.new(control)
      parse_job(control, context, [transforms])
      Kiba.run(control)
    end
  end

  def marc_file
    File.join(fixtures_dir, "harvard_open_data.mrc")
  end

  # @param path [String] path to MARC binary file (.mrc, .dat, etc)
  # @param index [Integer] which record from file you want to use in your
  #   test. Count starts at 0.
  def get_marc_record(index:, path: marc_file)
    recs = []
    MARC::Reader.new(path).each { |rec| recs << rec }
    recs[index]
  end

  def populate_registry(more_entries: {})
    fkeypath = File.join(fixtures_dir, "existing.csv")
    nofilepath = File.join(fixtures_dir, "not_here.csv")
    entries = {
      fkey: {path: fkeypath, supplied: true, lookup_on: :id},
      invalid: {},
      fee: {path: fkeypath, lookup_on: :foo, supplied: true},
      foo: {
        path: fkeypath,
        creator: Helpers.method(:test_csv),
        tags: %i[test]
      },
      bar: {
        path: fkeypath,
        creator: Helpers.method(:lookup_csv),
        tags: %i[test report]
      },
      baz: {
        path: fkeypath,
        creator: Kiba::Extend::Utils::Lookup.method(:csv_to_hash),
        tags: %i[report]
      },
      warn: {
        path: fkeypath,
        dest_class: Kiba::Extend::Destinations::CSV,
        creator: Kiba::Extend.method(:csvopts),
        dest_special_opts: {initial_headers: %i[objectnumber
          briefdescription]}
      },
      json_arr: {
        path: File.join(fixtures_dir, "output.json"),
        dest_class: Kiba::Extend::Destinations::JsonArray,
        creator: Helpers.method(:fake_creator_method)
      },
      noresultfile: {
        path: nofilepath,
        creator: Helpers.method(:fake_creator_with_no_job_output)
      },
      resultfile: {
        path: nofilepath,
        creator: Helpers.method(:fake_creator_with_job_output)
      }
    }.merge(more_entries)
    entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
    Kiba::Extend.registry.namespace(:ns) do
      namespace(:sub) do
        register(:fkey, {path: fkeypath, supplied: true})
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
    FileUtils.touch(File.join(fixtures_dir, "base_job_missing.csv"))
  end

  class OutputJob
    attr_reader :outrows

    def initialize(rowct)
      @outrows = rowct
    end
  end

  def fake_creator_with_no_job_output
    OutputJob.new(0)
  end

  def fake_creator_with_job_output
    OutputJob.new(101)
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
    File.join(tmp_dir, "test.csv")
  end

  def lookup_csv
    File.join(tmp_dir, "lkup.csv")
  end

  def generate_csv(rows)
    CSV.open(test_csv, "w") do |csv|
      rows.each { |row| csv << row }
    end
  end

  def generate_lookup_csv(rows)
    CSV.open(lookup_csv, "w") do |csv|
      rows.each { |row| csv << row }
    end
  end

  def execute_job(filename:, xform:, csvopt: {}, xformopt: {})
    output_rows = []
    settings = {filename: filename,
                csv_options: Kiba::Extend.csvopts.merge(csvopt)}
    job = Kiba.parse do
      source Kiba::Common::Sources::CSV, **settings
      transform(&:to_h)
      transform xform, **xformopt
      transform { |row| output_rows << row }
    end

    Kiba.run(job)
    output_rows
  end

  def job_csv(filename:, incsvopt: {}, outcsvopt: {})
    insettings = {filename: filename,
                  csv_options: Kiba::Extend.csvopts.merge(incsvopt)}
    outsettings = {filename: filename,
                   csv_options: Kiba::Extend.csvopts.merge(outcsvopt)}
    job = Kiba.parse do
      source Kiba::Common::Sources::CSV, **insettings
      transform(&:to_h)
      destination Kiba::Common::Destinations::CSV, **outsettings
    end
    Kiba.run(job)

    output_rows = []
    job2 = Kiba.parse do
      source Kiba::Common::Sources::CSV, **insettings
      transform(&:to_h)
      transform { |row| output_rows << row }
    end
    Kiba.run(job2)
    output_rows
  end
end
