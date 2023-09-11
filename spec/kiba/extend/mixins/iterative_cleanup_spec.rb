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
  setting :job_tags, default: %i[test cleanup], reader: true
  setting :worksheet_add_fields,
    default: %i[type note],
    reader: true
  setting :worksheet_field_order,
    default: %i[value type note],
    reader: true
  setting :fingerprint_fields,
    default: %i[value type note],
    reader: true
  setting :fingerprint_flag_ignore_fields, default: nil, reader: true
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
  end
end