# frozen_string_literal: true

require "spec_helper"

# used to test creator validation below
module Helpers
  module Project
    module_function

    module Section
      module_function

      def desc
        <<~DESC
          Here is the job description.

          Blah blah blah.
        DESC
      end

      def job
      end
    end

    module JoblessSection
      module_function

      def procable
        Helpers::Project::Section
      end
    end

    def headers
      %i[a b c]
    end
  end
end

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Registry::FileRegistryEntry" do
  let(:path) { File.join("spec", "fixtures", "fkey.csv") }
  let(:entry) { Kiba::Extend::Registry::FileRegistryEntry.new(data) }

  context "with MARC source" do
    let(:path) { File.join("spec", "fixtures", "harvard_open_data.mrc") }

    context "when job entry (not supplied)" do
      let(:data) do
        {
          path: path,
          src_class: Kiba::Extend::Sources::Marc
        }
      end

      it "returns invalid" do
        expect(entry.valid?).to be false
      end
    end

    context "when supplied entry" do
      let(:data) do
        {
          path: path,
          src_class: Kiba::Extend::Sources::Marc,
          supplied: true
        }
      end

      it "returns valid" do
        expect(entry.valid?).to be true
      end
    end

    context "when supplied entry with lookup_on" do
      let(:data) do
        {
          path: path,
          supplied: true,
          src_class: Kiba::Extend::Sources::Marc,
          lookup_on: :id
        }
      end

      it "returns invalid" do
        expect(entry.valid?).to be false
        errkey = entry.errors.key?(:cannot_lookup_from_nonCSV_supplied_source)
        expect(errkey).to be true
      end
    end
  end

  context "with MARC destination" do
    let(:path) { File.join("spec", "fixtures", "harvard_open_data.mrc") }

    context "when job entry (not supplied)" do
      let(:data) do
        {
          path: path,
          dest_class: Kiba::Extend::Destinations::Marc
        }
      end

      it "returns valid" do
        expect(entry.valid?).to be false
      end
    end

    context "when job entry with lookup_on" do
      let(:data) do
        {
          path: path,
          dest_class: Kiba::Extend::Destinations::Marc,
          lookup_on: :id
        }
      end

      it "returns invalid" do
        expect(entry.valid?).to be false
        errkey = entry.errors.key?(:cannot_lookup_from_nonCSV_destination)
        expect(errkey).to be true
      end
    end
  end

  context "with valid data" do
    let(:data) { {path: path, creator: Helpers.method(:test_csv)} }
    it "valid as expected" do
      expect(entry.path).to eq(Pathname.new(path))
      expect(entry.valid?).to be true
    end
  end

  context "when :dest_special_opts[:initial_headers] is an Array" do
    let(:data) do
      {
        path: path,
        creator: Helpers.method(:test_csv),
        dest_special_opts: {initial_headers: Helpers::Project.headers}
      }
    end

    it "valid as expected" do
      expect(entry.valid?).to be true
      expect(entry.dest_special_opts[:initial_headers]).to eq(%i[a b c])
    end
  end

  context "when :dest_special_opts[:initial_headers] is a Proc" do
    let(:data) do
      {
        path: path,
        creator: Helpers.method(:test_csv),
        dest_special_opts: {initial_headers: proc {
                                               Helpers::Project.headers.reverse
                                             }}
      }
    end

    it "valid as expected" do
      expect(entry.valid?).to be true
      expect(entry.dest_special_opts[:initial_headers]).to eq(%i[c b a])
    end
  end

  context "when :desc is a Proc" do
    let(:data) do
      {
        path: path,
        creator: Helpers.method(:test_csv),
        desc: proc { Helpers::Project::Section.desc }
      }
    end

    it "valid as expected" do
      expect(entry.valid?).to be true
      expect(entry.desc).to eq(Helpers::Project::Section.desc)
    end
  end

  context "without path" do
    context "when CSV source/dest" do
      let(:data) { {pat: path, supplied: true} }
      it "invalid as expected" do
        expect(entry.path).to be_nil
        expect(entry.valid?).to be false
        expect(entry.errors.key?(:missing_path)).to be true
      end
    end

    context "when un-written source/dest" do
      let(:data) {
        {src_class: Kiba::Extend::Sources::Enumerable,
         dest_class: Kiba::Extend::Destinations::Lambda,
         supplied: true}
      }
      it "valid as expected" do
        expect(entry.path).to be_nil
        expect(entry.valid?).to be true
      end
    end
  end

  context "without creator" do
    context "when supplied file" do
      let(:data) { {path: path, supplied: true} }
      it "valid" do
        expect(entry.valid?).to be true
      end
    end

    context "when not a supplied file" do
      let(:data) { {path: path} }
      it "invalid as expected" do
        expect(entry.valid?).to be false
        expect(entry.errors[:missing_creator_for_non_supplied_file]).to be_nil
      end
    end
  end

  context "with non-method creator" do
    context "when a String" do
      let(:data) { {path: path, creator: "a string"} }
      it "invalid as expected" do
        expect(entry.creator).to be_nil
        expect(entry.valid?).to be false
        expect(entry.errors.key?("Kiba::Extend::Registry::Creator::TypeError")).to be true
      end
    end

    context "when a Module not containing a `job` method, and no method given" do
      let(:data) { {path: path, creator: Helpers::Project::JoblessSection} }
      it "invalid as expected" do
        expect(entry.creator).to be_nil
        expect(entry.valid?).to be false
        expect(entry.errors.key?("Kiba::Extend::Registry::Creator::JoblessModuleCreatorError")).to be true
      end
    end

    context "when a Module containing a `job` method, and no method given" do
      let(:data) { {path: path, creator: Helpers::Project::Section} }
      it "valid as expected" do
        expect(entry.valid?).to be true
      end
    end

    context "when a Proc returning valid job" do
      let(:data) {
        {path: path, creator: proc {
                                Helpers::Project::JoblessSection.send(:procable)
                              }}
      }
      it "valid as expected" do
        expect(entry.valid?).to be true
      end
    end

    context "when a Proc returning invalid job" do
      let(:data) {
        {path: path, creator: proc {
                                Helpers::Project::JoblessSection
                              }}
      }
      it "valid as expected" do
        expect(entry.valid?).to be false
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
