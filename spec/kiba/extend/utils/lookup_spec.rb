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
end
