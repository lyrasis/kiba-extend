# frozen_string_literal: true

require "marc"
require "spec_helper"

RSpec.describe "Kiba::Extend::Jobs::MarcJob" do
  subject(:marcjob) do
    Kiba::Extend::Jobs::MarcJob.new(files: config, transformer: xforms)
  end

  context "with Marc source, CSV dest" do
    before(:context) do
      reg = Kiba::Extend::Registry::FileRegistry.new
      Kiba::Extend.config.registry = reg
      @dest_file = File.join(fixtures_dir, "marc_job_dest.csv")
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
      entries = {
        marc_src: {
          path: marc_file,
          supplied: true,
          src_class: Kiba::Extend::Sources::Marc
        },
        marc_dest: {
          path: @dest_file,
          creator: Helpers.method(:fake_creator_method)
        }
      }
      entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
      transform_registry
    end
    after(:context) do
      Kiba::Extend.reset_config
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
    end

    let(:config) do
      {
        source: [:marc_src],
        destination: [:marc_dest]
      }
    end

    let(:xforms) do
      Kiba.job_segment do
        transform Kiba::Extend::Transforms::Marc::Extract245Title
      end
    end

    it "runs and produces expected result" do
      marcjob.run
      result = CSV.table(@dest_file)
      expect(result).to be_a(CSV::Table)
    end
  end

  context "with Marc source, Marc dest" do
    before(:context) do
      reg = Kiba::Extend::Registry::FileRegistry.new
      Kiba::Extend.config.registry = reg
      @dest_file = File.join(fixtures_dir, "marc_job_dest.mrc")
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
      entries = {
        marc_src: {
          path: marc_file,
          supplied: true,
          src_class: Kiba::Extend::Sources::Marc
        },
        marc_dest: {
          path: @dest_file,
          creator: Helpers.method(:fake_creator_method),
          dest_class: Kiba::Extend::Destinations::Marc
        }
      }
      entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
      transform_registry
    end
    after(:context) do
      Kiba::Extend.reset_config
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
    end

    let(:config) do
      {
        source: [:marc_src],
        destination: [:marc_dest]
      }
    end

    let(:xforms) do
      Kiba.job_segment do
      end
    end

    let(:recs) do
      recs = []
      MARC::Reader.new(@dest_file).each { |rec| recs << rec }
      recs
    end

    it "runs and produces expected result" do
      marcjob.run
      expect(recs.first).to be_a(MARC::Record)
      expect(recs.length).to eq(10)
    end
  end

  context "with CSV source, CSV dest; init xform expecting MARC" do
    before(:context) do
      reg = Kiba::Extend::Registry::FileRegistry.new
      Kiba::Extend.config.registry = reg
      @src_file = File.join(fixtures_dir, "existing.csv")
      @dest_file = File.join(fixtures_dir, "marc_job_dest.csv")
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
      entries = {
        marc_job_csv_src: {
          path: @src_file,
          supplied: true,
          src_class: Kiba::Extend::Sources::CSV
        },
        marc_job_csv_dest: {
          path: @dest_file,
          creator: Helpers.method(:fake_creator_method)
        }
      }
      entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
      transform_registry
    end
    after(:context) do
      Kiba::Extend.reset_config
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
    end

    let(:config) do
      {
        source: [:marc_job_csv_src],
        destination: [:marc_job_csv_dest]
      }
    end

    let(:xforms) do
      Kiba.job_segment do
        transform Kiba::Extend::Transforms::Marc::Extract245Title
      end
    end

    # The initial Transform defined in the job expects a `MARC::Record`, not a
    #   `CSV::Row`.
    it "raises error because xform can't handle CSV row" do
      expect { marcjob.run }.to raise_error(SystemExit)
    end
  end

  context "with CSV source, CSV dest; init xform expecting CSV" do
    before(:context) do
      reg = Kiba::Extend::Registry::FileRegistry.new
      Kiba::Extend.config.registry = reg
      @src_file = File.join(fixtures_dir, "existing.csv")
      @dest_file = File.join(fixtures_dir, "marc_job_dest.csv")
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
      entries = {
        marc_job_csv_src: {
          path: @src_file,
          supplied: true,
          src_class: Kiba::Extend::Sources::CSV
        },
        marc_job_csv_dest: {
          path: @dest_file,
          creator: Helpers.method(:fake_creator_method)
        }
      }
      entries.each { |key, data| Kiba::Extend.registry.register(key, data) }
      transform_registry
    end
    after(:context) do
      Kiba::Extend.reset_config
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
    end

    let(:config) do
      {
        source: [:marc_job_csv_src],
        destination: [:marc_job_csv_dest]
      }
    end

    let(:xforms) do
      Kiba.job_segment do
        transform Kiba::Extend::Transforms::Delete::Fields,
          fields: :numberOfObjects
      end
    end

    # This does not fail on the transforms, because `CSV::Row` has
    #   much the same interface as a `Hash` for getting and setting
    #   field values. It fails when the Destination tries to write a
    #   CSV in a way that works with `Hash`es, but not for `CSV::Row`s.
    it "raises error because job didn't convert CSV::Row to Hash" do
      expect { marcjob.run }.to raise_error(SystemExit)
    end
  end
end
