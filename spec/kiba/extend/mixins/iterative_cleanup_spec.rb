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
end
