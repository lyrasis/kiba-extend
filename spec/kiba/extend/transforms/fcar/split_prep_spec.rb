# frozen_string_literal: true

require "spec_helper"

# These are internal class tests. User-facing behavior test examples
#   in yardspec
RSpec.describe Kiba::Extend::Transforms::Fcar::SplitPrep do
  subject(:xform) do
    described_class.new(splitters: [",", ";"], orig: :val)
  end

  let(:input) { [{val: "foo"}, {val: nil}] }

  let(:result) do
    Kiba::StreamingRunner.transform_stream(input, xform)
      .map { |r| r }
  end

  it "raises error" do
    expect { result }.to raise_error(Kiba::Extend::BlankFcarOrigFieldError)
  end
end
