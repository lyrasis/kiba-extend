# frozen_string_literal: true

require "spec_helper"

module WithoutBaseJob
  module_function

  extend Dry::Configurable

  setting :cleanup_base_name, default: :test__me, reader: true
end

module WithSetup
  module_function

  extend Dry::Configurable

  setting :base_job, default: :base__job, reader: true
  setting :fingerprint_fields,
    default: %i[value type note],
    reader: true
end

module RegNamespace
  module_function

  def datadir = Helpers.fixtures_dir

  module WithFiles
    module_function

    extend Dry::Configurable

    setting :base_job, default: :base__job, reader: true
    setting :fingerprint_fields,
      default: %i[value type note],
      reader: true

    extend Kiba::Extend::Mixins::IterativeCleanup

    def worksheets_provided = ["ws.csv", "ws2.csv", "ws3.csv"]
    def returned_files = ["ret1.csv", "ret2.csv"]

    def returned_file_xforms = Kiba.job_segment do
      # your transforms here
    end
  end
end

module WithoutDryConfig
  module_function

  def base_job
    :base__job
  end

  def fingerprint_fields
    %i[value type note]
  end
end

RSpec.describe Kiba::Extend::Mixins::IterativeCleanup do
  let(:subject) { described_class }

  describe ".extended" do
    context "when extended without :base_job" do
      let(:mod) { WithoutBaseJob }

      it "raises error" do
        expect { mod.extend(subject) }.to raise_error(
          Kiba::Extend::IterativeCleanupSettingUndefinedError
        )
      end
    end

    context "when extended with required setup" do
      let(:mod) { WithSetup }

      it "extends IterativeCleanup" do
        mod.extend(subject)
        expect(mod).to be_a(subject)
        expect(mod).to respond_to(:provided_worksheets, :returned_files,
          :returned_file_jobs, :cleanup_done?)
        expect(mod.cleanup_base_name).to eq("with_setup")
      end
    end

    context "when extending module has not extended Dry::Configurable" do
      let(:mod) { WithoutDryConfig }

      it "extends IterativeCleanup" do
        mod.extend(subject)
        expect(mod).to be_a(subject)
        expect(mod).to respond_to(:provided_worksheets, :returned_files,
          :returned_file_jobs, :cleanup_done?)
        expect(mod.cleanup_base_name).to eq("without_dry_config")
      end
    end
  end

  describe ".returned_files" do
    let(:result) { mod.returned_files }
    let(:mod) { RegNamespace::WithFiles }

    it "returns listed files" do
      expect(result).to eq(["ret1.csv", "ret2.csv"])
    end

    context "without defined returned_files" do
      let(:mod) { WithSetup }

      it "returns empty array" do
        mod.extend(subject)
        expect(result).to eq([])
      end
    end
  end

  describe ".returned_file_jobs" do
    let(:result) { mod.returned_file_jobs }
    let(:mod) { RegNamespace::WithFiles }

    it "returns standardized job keys" do
      expect(result).to eq(
        %i[with_files__file_returned_0 with_files__file_returned_1]
      )
    end

    context "without defined returned_files" do
      let(:mod) { WithSetup }

      it "returns empty array" do
        mod.extend(subject)
        expect(result).to eq([])
      end
    end
  end

  describe ".returned_file_xforms" do
    let(:result) { mod.returned_file_xforms }
    let(:mod) { RegNamespace::WithFiles }

    it "returns Kiba.job_segment proc" do
      expect(result).to be_a(Proc)
    end

    context "without defined returned_file_xforms" do
      let(:mod) { WithSetup }

      it "returns nil" do
        mod.extend(subject)
        expect(result).to be_nil
      end
    end
  end

  describe ".register_cleanup_jobs" do
    context "with returned file xforms" do
      before do
        Kiba::Extend.config.config_namespaces = [RegNamespace]
        Kiba::Extend::Utils::IterativeCleanupJobRegistrar.call
        Kiba::Extend.registry.finalize
      end
      after { Kiba::Extend.reset_config }

      it "registers processed return file jobs" do
        chk = %w[
          with_files__file_returned_0_processed
          with_files__file_returned_1_processed
        ] - Kiba::Extend.registry.keys
        expect(chk).to be_empty
      end
    end
  end
end
