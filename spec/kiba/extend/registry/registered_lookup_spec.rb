# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Registry::RegisteredLookup" do
  let(:filekey) { :fkey }
  let(:path) { File.join("spec", "fixtures", "fkey.csv") }
  let(:key) { :foo }
  let(:default) do
    {path: path, lookup_on: key, creator: Helpers.method(:test_csv)}
  end
  let(:lookup) do
    Kiba::Extend::Registry::RegisteredLookup.new(
      key: filekey,
      data: Kiba::Extend::Registry::FileRegistryEntry.new(data),
      for_job: :bar
    )
  end

  context "when called without lookup_on value" do
    let(:data) { {path: path} }
    it "raises NoLookupOnError" do
      expect do
        lookup
      end.to raise_error(
        Kiba::Extend::NoLookupOnError
      )
    end
  end

  context "when called with non-Symbol lookup_on value" do
    let(:data) { {path: path, lookup_on: "bar"} }
    it "raises NonSymbolLookupOnError" do
      expect do
        lookup
      end.to raise_error(
        Kiba::Extend::NonSymbolLookupOnError
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

    it "raises JobCannotBeUsedAsLookupError" do
      expect { lookup }.to raise_error(
        Kiba::Extend::JobCannotBeUsedAsLookupError,
        ":fkey cannot be used as a lookup in :bar because its src_class "\
          "(Kiba::Extend::Sources::Marc) does not include "\
          "Kiba::Extend::Soures::Lookupable"
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

    it "raises JobCannotBeUsedAsLookupError" do
      expect { lookup }.to raise_error(
        Kiba::Extend::JobCannotBeUsedAsLookupError,
        ":fkey cannot be used as a lookup in :bar because its src_class "\
          "(Kiba::Extend::Sources::Marc) does not include "\
          "Kiba::Extend::Soures::Lookupable"
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
