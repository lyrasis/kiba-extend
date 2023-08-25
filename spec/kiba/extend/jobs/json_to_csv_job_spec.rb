# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Jobs::JsonToCsvJob" do
  subject(:job) do
    Kiba::Extend::Jobs::JsonToCsvJob.new(files: config, transformer: xforms)
  end

  context "with JsonDir source" do
    before(:context) do
      reg = Kiba::Extend::Registry::FileRegistry.new
      Kiba::Extend.config.registry = reg
      @dest_file = File.join(fixtures_dir, "json_to_csv_job_dest.csv")
      FileUtils.rm(@dest_file) if File.exist?(@dest_file)
      entries = {
        json_dir_src: {
          path: File.join(fixtures_dir, "json_dir"),
          supplied: true,
          src_class: Kiba::Extend::Sources::JsonDir,
          src_opt: {recursive: true, filesuffixes: [".json", ".txt"]}
        },
        csv_dest: {
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
        source: [:json_dir_src],
        destination: [:csv_dest]
      }
    end

    let(:xforms) do
      Kiba.job_segment do
        transform Delete::Fields, fields: :id
      end
    end

    it "runs and produces expected result" do
      job
      result = CSV.table(@dest_file)
      expect(result.size).to eq(4)
    end
  end
end
# rubocop:enable Metrics/BlockLength
