# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::SepDeprecatable do
  class Xform
    include Kiba::Extend::Transforms::SepDeprecatable
  end

  subject(:mod) { Xform.new }

  describe "#usedelim" do
    let(:result) { mod.usedelim(**params) }

    context "with delim and no sep" do
      let(:params) { {sepval: nil, delimval: "|", calledby: mod} }

      it "returns expected" do
        expect(result).to eq("|")
        expect(mod).not_to receive(:warn)
      end
    end

    context "with sep and no delim" do
      let(:warning) do
        "#{Kiba::Extend.warning_label}:\n  Xform: `sep` parameter will "\
          "be deprecated in a future release.\nTO FIX:\n  Change `sep` "\
          "to `delim`"
      end
      let(:params) { {sepval: "|", delimval: nil, calledby: mod} }

      it "returns expected" do
        expect(mod).to receive(:warn).with(warning)
        expect(result).to eq("|")
      end
    end

    context "with sep and delim" do
      let(:warning) do
        "#{Kiba::Extend.warning_label}:\n  Xform: `sep` and `delim` "\
          "parameters given. `delim` value used. `sep` value ignored. "\
          "`sep` will be deprecated in a future release.\n"\
          "TO FIX:\n  Remove `sep` param"
      end
      let(:params) { {sepval: ";", delimval: "|", calledby: mod} }

      it "returns expected" do
        expect(mod).to receive(:warn).with(warning)
        expect(result).to eq("|")
      end
    end

    context "without sep or delim" do
      let(:params) { {sepval: nil, delimval: nil, calledby: mod} }

      it "returns expected" do
        expect { result }.to raise_error(
          ArgumentError,
          "Xform: missing keyword: :delim"
        )
      end
    end
  end
end
