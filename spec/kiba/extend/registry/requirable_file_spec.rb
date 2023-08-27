# frozen_string_literal: true

require "spec_helper"

class TestClass < Kiba::Extend::Registry::RegisteredFile
  include Kiba::Extend::Registry::RequirableFile
end

# rubocop:disable Metrics/BlockLength
RSpec.describe "Kiba::Extend::Registry::RequirableFile" do
  let(:filekey) { :fkey }
  let(:path) { File.join("spec", "fixtures", "fkey.csv") }
  let(:default) do
    {path: path, creator: Helpers.method(:fake_creator_method)}
  end
  let(:klass) do
    TestClass.new(key: filekey,
      data: Kiba::Extend::Registry::FileRegistryEntry.new(data))
  end

  context "when called without creator" do
    let(:data) { {path: path} }
    it "raises NoDependencyCreatorError" do
      msg = "No creator method found for :#{filekey} in file registry"
      expect do
        TestClass.new(key: filekey,
          data: Kiba::Extend::Registry::FileRegistryEntry.new(data)).required
      end.to raise_error(
        Kiba::Extend::Registry::RequirableFile::NoDependencyCreatorError, msg
      )
    end
  end

  describe "#required" do
    let(:result) { klass.required }
    let(:data) { default }
    context "when file does not exist at path" do
      it "returns Creator", :aggregate_failures do
        expect(result).to be_a(Kiba::Extend::Registry::Creator)
        expect(result.mod).to eq(Helpers)
        expect(result.meth).to eq(:fake_creator_method)
      end
    end

    context "when file exists at path" do
      let(:path) { File.join(fixtures_dir, "base_job_base.csv") }
      it "returns nil" do
        expect(result).to be nil
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
