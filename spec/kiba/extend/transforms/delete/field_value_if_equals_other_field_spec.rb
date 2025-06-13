# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Delete::FieldValueIfEqualsOtherField do
  subject(:xform) { described_class.new(**params) }

  let(:result) do
    Kiba::StreamingRunner.transform_stream(input, xform)
      .map { |row| row }
  end

  context "with ragged grouped fields" do
    let(:input) do
      [
        {del: "A;C;d;e;c", compare: "c", grpa: "y;x;w;u", grpb: "e;f;g;h;i"}
      ]
    end

    let(:params) do
      {
        delete: :del,
        if_equal_to: :compare,
        multival: true,
        delim: ";",
        grouped_fields: %i[grpa grpb],
        casesensitive: false
      }
    end

    it "outputs warning to STDOUT" do
      msg = /KIBA WARNING: One or more grouped fields.*/
      expect { result }.to output(msg).to_stdout
    end
  end
end
