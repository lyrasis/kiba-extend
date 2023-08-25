# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Registry::RegisteredLookup" do
  let(:filekey) { :fkey }
  let(:path) { File.join("spec", "fixtures", "fkey.csv") }
  let(:key) { :foo }
  let(:default) {
    {path: path, lookup_on: key, creator: Helpers.method(:test_csv)}
  }
  let(:lookup) do
    Kiba::Extend::Registry::RegisteredLookup.new(
      key: filekey,
      data: Kiba::Extend::Registry::FileRegistryEntry.new(data)
    )
  end

  context "when called without lookup key" do
    let(:data) { {path: path} }
    it "raises NoLookupKeyError" do
      msg = "No lookup key column found for :#{filekey} in file registry hash"
      expect {
        lookup
      }.to raise_error(
        Kiba::Extend::Registry::RegisteredLookup::NoLookupKeyError, msg
      )
    end
  end

  context "when called with unlookupable src" do
    let(:data) do
      {
        path: path,
        lookup_on: key,
        supplied: true,
        src_class: Kiba::Extend::Sources::Marc
      }
    end

    it "raises CannotBeUsedAsLookupError" do
      expect { lookup }.to raise_error(
        Kiba::Extend::Registry::RegisteredLookup::CannotBeUsedAsLookupError
      )
    end
  end

  context "when called with unlookupable dest" do
    let(:data) do
      {
        path: path,
        lookup_on: key,
        creator: Helpers.method(:test_csv),
        dest_class: Kiba::Extend::Destinations::Marc
      }
    end

    it "raises CannotBeUsedAsLookupError" do
      expect { lookup }.to raise_error(
        Kiba::Extend::Registry::RegisteredLookup::CannotBeUsedAsLookupError
      )
    end
  end

  describe "#args" do
    let(:result) { lookup.args }
    context "with basic defaults" do
      let(:data) { default }
      let(:expected) do
        {file: path, csvopt: Kiba::Extend.csvopts, keycolumn: key}
      end
      it "returns with default csvopts" do
        expect(result).to eq(expected)
      end
    end

    context "with given options" do
      let(:override_opts) { {foo: :bar} }
      let(:data) { default.merge({src_opt: override_opts}) }
      let(:expected) do
        {file: path, csvopt: override_opts, keycolumn: key}
      end
      it "returns with given options" do
        expect(result).to eq(expected)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
