# frozen_string_literal: true

require "spec_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Registry::RegisteredSource" do
  let(:filekey) { :fkey }
  let(:path) { File.join("spec", "fixtures", "fkey.csv") }
  let(:default) { {path: path, creator: -> { Helpers.test_csv }} }
  let(:source) do
    Kiba::Extend::Registry::RegisteredSource.new(
      key: filekey,
      data: Kiba::Extend::Registry::FileRegistryEntry.new(data)
    )
  end

  describe "#args" do
    let(:result) { source.args }

    context "with basic defaults" do
      let(:data) { default }
      let(:expected) do
        {filename: path, csv_options: Kiba::Extend.csvopts}
      end
      it "returns with Kiba::Extend default csvopts" do
        expect(result).to eq(expected)
      end
    end

    context "with given options" do
      let(:override_opts) { {foo: :bar} }
      let(:data) { {path: path, src_opt: override_opts} }
      let(:expected) do
        {filename: path, csv_options: override_opts}
      end
      it "returns with given opts" do
        expect(result).to eq(expected)
      end
    end

    context "with JsonDir source" do
      let(:path) { File.join(fixtures_dir, "json_dir") }
      let(:src_class) { Kiba::Extend::Sources::JsonDir }

      context "with path only" do
        let(:data) do
          {
            path: path,
            supplied: true,
            src_class: src_class
          }
        end
        let(:expected) { {dirpath: path} }

        it "returns default opts" do
          expect(result).to eq(expected)
        end
      end

      context "with src_opt" do
        let(:data) do
          {
            path: path,
            supplied: true,
            src_class: src_class,
            src_opt: {recursive: true}
          }
        end
        let(:expected) { {dirpath: path, recursive: true} }

        it "returns specified opts" do
          expect(result).to eq(expected)
        end
      end
    end

    context "with MARC source" do
      let(:path) { File.join("spec", "fixtures", "harvard_open_data.mrc") }

      context "with path only" do
        let(:data) do
          {
            path: path,
            supplied: true,
            src_class: Kiba::Extend::Sources::Marc
          }
        end
        let(:expected) { {filename: path} }

        it "returns default opts" do
          expect(result).to eq(expected)
        end
      end

      context "with src_opt" do
        let(:data) do
          {
            path: path,
            supplied: true,
            src_class: Kiba::Extend::Sources::Marc,
            src_opt: {external_encoding: "UTF-8"}
          }
        end
        let(:expected) { {filename: path, args: {external_encoding: "UTF-8"}} }

        it "returns default opts" do
          expect(result).to eq(expected)
        end
      end
    end
  end

  describe "#klass" do
    let(:result) { source.klass }
    context "with basic defaults" do
      let(:data) { default }
      it "returns Kiba::Extend default source class" do
        expect(result).to eq(Kiba::Extend.source)
      end
    end

    context "with supplied entry with MARC source" do
      let(:data) do
        {path: path, src_class: Kiba::Extend::Sources::Marc, supplied: true}
      end

      it "returns given class" do
        expect(result).to eq(Kiba::Extend::Sources::Marc)
      end
    end

    context "with job entry with MARC source and CSV dest" do
      let(:data) do
        {
          path: path,
          src_class: Kiba::Extend::Sources::Marc,
          creator: -> { Helpers.test_csv },
          dest_class: Kiba::Extend::Destinations::CSV
        }
      end

      it "returns given class" do
        expect(result).to eq(Kiba::Extend::Sources::CSV)
      end
    end

    context "with job entry with CSV source and Lambda dest" do
      let(:data) do
        {
          path: path,
          src_class: Kiba::Extend::Sources::CSV,
          creator: -> { Helpers.test_csv },
          dest_class: Kiba::Extend::Destinations::Lambda
        }
      end

      it "raises error" do
        expect { result }.to raise_error(
          Kiba::Extend::Registry::CannotBeUsedAsSourceError,
          "The result of a registry entry with a "\
            "Kiba::Extend::Destinations::Lambda dest_class cannot "\
            "be used as source file in a job"
        )
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
