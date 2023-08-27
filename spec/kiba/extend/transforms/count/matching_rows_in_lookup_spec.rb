# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Extend::Transforms::Count::MatchingRowsInLookup do
  before do
    generate_csv(rows)
  end
  after do
    File.delete(test_csv) if File.exist?(test_csv)
  end

  let(:rows) do
    [
      ["id"],
      [0],
      [1],
      [2]
    ]
  end
  let(:lookup_rows) do
    [
      ["id"],
      [1],
      [2],
      [2]
    ]
  end
  let(:lookup) do
    Lookup.csv_to_hash(file: lookup_csv, csvopt: Kiba::Extend.csvopts,
      keycolumn: :id)
  end
  let(:xformopt) do
    {
      lookup: lookup,
      keycolumn: :id,
      targetfield: :ct
    }
  end
  before do
    generate_lookup_csv(lookup_rows)
  end

  context "with default result_type (:str)" do
    # rubocop:todo Layout/LineLength
    it "merges count of lookup rows to be merged into specified field as string" do
      # rubocop:enable Layout/LineLength
      expected = [
        {id: "0", ct: "0"},
        {id: "1", ct: "1"},
        {id: "2", ct: "2"}
      ]
      result = execute_job(filename: test_csv,
        xform: Count::MatchingRowsInLookup, xformopt: xformopt)
      expect(result).to eq(expected)
    end
  end

  context "with result_type :int" do
    let(:xformopt) do
      {
        lookup: lookup,
        keycolumn: :id,
        targetfield: :ct,
        result_type: :int
      }
    end
    # rubocop:todo Layout/LineLength
    it "merges count of lookup rows to be merged into specified field as integer" do
      # rubocop:enable Layout/LineLength
      expected = [
        {id: "0", ct: 0},
        {id: "1", ct: 1},
        {id: "2", ct: 2}
      ]
      result = execute_job(filename: test_csv,
        xform: Count::MatchingRowsInLookup, xformopt: xformopt)
      expect(result).to eq(expected)
    end
  end
end
