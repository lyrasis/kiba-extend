# frozen_string_literal: true

require "spec_helper"

# These are internal class tests focused on ensuring that the
#   fields/targets relationship works as expected. User-facing
#   behavior test examples in yardspec
RSpec.describe Kiba::Extend::Transforms::Normalize::FieldValues do
  subject(:xform) { described_class.new(**args) }

  context "with single field, no targets" do
    let(:args) { {fields: :a, xforms: %i[blanks]} }

    it "creates transformer" do
      expect(xform.respond_to?(:process)).to be true
    end
  end

  context "with multiple fields, no targets" do
    let(:args) { {fields: %i[a b], xforms: %i[blanks]} }

    it "creates transformer" do
      expect(xform.respond_to?(:process)).to be true
    end
  end

  context "with single field, balanced targets" do
    let(:args) { {fields: :a, targets: :b, xforms: %i[blanks]} }

    it "creates transformer" do
      expect(xform.respond_to?(:process)).to be true
    end
  end

  context "with single field, unbalanced targets" do
    let(:args) { {fields: :a, targets: %i[b c], xforms: %i[blanks]} }

    it "creates transformer" do
      expect { xform }.to raise_error(Kiba::Extend::UnbalancedFieldsTargetsError)
    end
  end

  context "with multiple fields, balanced targets" do
    let(:args) { {fields: %i[a b], targets: %i[c d], xforms: %i[blanks]} }

    it "creates transformer" do
      expect(xform.respond_to?(:process)).to be true
    end
  end

  context "with multiple fields, unbalanced targets" do
    let(:args) { {fields: %i[a b z], targets: %i[c d], xforms: %i[blanks]} }

    it "creates transformer" do
      expect { xform }.to raise_error(Kiba::Extend::UnbalancedFieldsTargetsError)
    end
  end
end
