# frozen_string_literal: true

module Helpers
  module_function


  class TestJob
    include Kiba::Extend::Jobs::Parser

    attr_reader :control, :context, :accumulator
    def initialize(input:, accumulator:, transforms:)
      @accumulator = accumulator
      @control = Kiba.parse do
        source Kiba::Common::Sources::Enumerable, input
        destination Kiba::Common::Destinations::Lambda,
          on_write: ->(r) { accumulator << r }
      end
      @context = Kiba::Context.new(control)
      parse_job(control, context, [transforms])
      Kiba.run(control)
    end
  end
  
  # Format examples for Yard documentation
  #
  # Use: Helpers::ExampleFormatter.new(input, expected)
  class ExampleFormatter
    def initialize(*args)
      args.each do |arg|
        @clean = nil
        @norm = nil
        @table = nil
        @headers = nil
        @maxes = {}
        @data = arg
        build_table
        put_table
      end
    end

    private

    def build_table
      clean_data
      populate_maxes
      normalize
      format_table
    end

    def clean_data
      @clean = []
      @data.each do |row|
        @clean << row.transform_values{ |val| val.nil? ? 'nil' : val  }
      end
    end

    def format_table
      @table = []
      @table << headers
      @table << grab_divider
      grab_rows
    end

    def headers
      @headers ||= @norm.first.keys
    end

    def grab_divider
      div = []
      headers.each do |header|
        segment = '-' * header.length
        div << segment
      end
      div
    end

    def grab_row(row)
      t_row = []
      headers.each do |header|
        t_row << row[header]
      end
      t_row
    end
    
    def grab_rows
      @norm.each{ |row| @table << grab_row(row) }
    end
    
    def max_val_length_for_header(header)
      @clean.map{ |row| row[header].length }.max
    end
    
    def normalize
      @norm = []
      @clean.each{ |row| @norm << normalize_row(row) }
    end

    def normalize_row(row)
      norm = {}
      row.each do |header, val|
        max = @maxes[header]
        norm[header.to_s.ljust(max)] = val.ljust(max)
      end
      norm
    end
    
    def populate_maxes
      @maxes = @clean.first.map{ |e| [e[0], e[0].length] }.to_h
      headers = @maxes.keys
      headers.each do |hdr|
        val_max = max_val_length_for_header(hdr)
        @maxes[hdr] = val_max if val_max > @maxes[hdr]
      end
    end

    def put_row(row)
      puts "# | #{row.join(' | ')} |"
    end  

    def put_table
      table = @table.dup
      puts ''
      puts '#'
      puts '# ```'
      put_row(table.shift)
      div = table.shift
      puts "# |-#{div.join('-+-')}-|"
      table.each{ |row| put_row(row) }
      puts '# ```'
      puts '#'
    end
  end

  
  
  def fixtures_dir
    app_dir = File.realpath(File.join(File.dirname(__FILE__), '..'))
    File.join(app_dir, 'spec', 'fixtures')
  end

  def populate_registry(more_entries: {})
    fkeypath = File.join(fixtures_dir, 'existing.csv')
    entries = { fkey: { path: fkeypath, supplied: true, lookup_on: :id },
               invalid: {},
               fee: { path: fkeypath, lookup_on: :foo, supplied: true },
               foo: { path: fkeypath, creator: Helpers.method(:test_csv), tags: %i[test] },
               bar: { path: fkeypath, creator: Helpers.method(:lookup_csv), tags: %i[test report] },
               baz: { path: fkeypath, creator: Kiba::Extend::Utils::Lookup.method(:csv_to_hash), tags: %i[report] },
               warn: { path: fkeypath, dest_class: Kiba::Common::Destinations::CSV,
                      creator: Kiba::Extend.method(:csvopts),
                      dest_special_opts: { initial_headers: %i[objectnumber briefdescription] } },
               json_arr: {path: fkeypath, dest_class: Kiba::Extend::Destinations::JsonArray,
                          creator: Helpers.method(:fake_creator_method)} }.merge(more_entries)
    entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
    Kiba::Extend.registry.namespace(:ns) do
      namespace(:sub) do
        register(:fkey, { path: fkeypath, supplied: true })
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
      source Kiba::Common::Sources::CSV, **settings
      transform(&:to_h)
      transform xform, **xformopt
      transform { |row| output_rows << row }
    end

    Kiba.run(job)
    output_rows
  end

  def job_csv(filename:, incsvopt: {}, outcsvopt: {})
    insettings = { filename: filename, csv_options: CSVOPT.merge(incsvopt) }
    outsettings = { filename: filename, csv_options: CSVOPT.merge(outcsvopt) }
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
