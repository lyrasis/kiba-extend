# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Utils::Lookup do
  rows = [
    %w[id val],
    %w[1 a],
    %w[2 b],
    %w[3 c],
    %w[3 d]
  ]
  before { generate_csv(rows) }
  after { File.delete(test_csv) if File.exist?(test_csv) }

  describe "#csv_to_hash" do
    lookup_hash = {
      "1" => [{id: "1", val: "a"}],
      "2" => [{id: "2", val: "b"}],
      "3" => [{id: "3", val: "c"},
        {id: "3", val: "d"}]
    }

    it "returns hash with key = keycolumn value and "\
      "value = array of all rows w/that key " do
        result = Lookup.csv_to_hash(file: test_csv,
          csvopt: Kiba::Extend.csvopts,
          keycolumn: :id)
        expect(result).to eq(lookup_hash)
      end
  end

  describe "#from_job" do
    before(:all) { populate_registry }
    after(:all) { Kiba::Extend.reset_config }
    let(:result) { Lookup.from_job(jobkey: jobkey, lookup_on: lookup_on) }
    let(:lookup_on) { nil }

    context "with unregistered job" do
      let(:jobkey) { :unr__unr }

      it "raises error" do
        expect { result }.to raise_error(Kiba::Extend::JobNotRegisteredError)
      end
    end

    context "with registered job with established lookup_on" do
      let(:jobkey) { :fkey }

      it "returns as expected" do
        expect(result).to be_a(Hash)
        expect(result[nil].length).to eq(2)
      end
    end

    context "with registered job with lookup_on override" do
      let(:jobkey) { :fkey }
      let(:lookup_on) { :objectnumber }

      it "returns as expected" do
        expect(result).to be_a(Hash)
        expect(result["OBJ1"].length).to eq(1)
      end
    end

    context "with registered job with dynamically provided lookup_on" do
      let(:jobkey) { :foo }
      let(:lookup_on) { :objectnumber }

      it "returns as expected" do
        expect(result).to be_a(Hash)
        expect(result["OBJ1"].length).to eq(1)
      end
    end

    context "with registered job without lookup_on" do
      let(:jobkey) { :foo }

      it "returns as expected" do
        expect { result }.to raise_error(Kiba::Extend::NoLookupOnError)
      end
    end
  end
end
