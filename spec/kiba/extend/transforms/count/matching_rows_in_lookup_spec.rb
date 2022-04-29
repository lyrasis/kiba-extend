# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Count::MatchingRowsInLookup do
  before do
    generate_csv(rows)
  end
  after do
    File.delete(test_csv) if File.exist?(test_csv)
  end

  let(:rows) do
    [
      ['id'],
      [0],
      [1],
      [2]
    ]
  end
  let(:lookup_rows) do
    [
      ['id'],
      [1],
      [2],
      [2]
    ]
  end
  let(:lookup) { Lookup.csv_to_hash(file: lookup_csv, csvopt: CSVOPT, keycolumn: :id) }
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

  context 'with default result_type (:str)' do
    it 'merges count of lookup rows to be merged into specified field as string' do
      expected = [
        { id: '0', ct: '0' },
        { id: '1', ct: '1' },
        { id: '2', ct: '2' }
      ]
      result = execute_job(filename: test_csv, xform: Count::MatchingRowsInLookup, xformopt: xformopt)
      expect(result).to eq(expected)
    end
  end

  context 'with result_type :int' do
    let(:xformopt) do
      {
        lookup: lookup,
        keycolumn: :id,
        targetfield: :ct,
        result_type: :int
      }
    end
    it 'merges count of lookup rows to be merged into specified field as integer' do
      expected = [
        { id: '0', ct: 0 },
        { id: '1', ct: 1 },
        { id: '2', ct: 2 }
      ]
      result = execute_job(filename: test_csv, xform: Count::MatchingRowsInLookup, xformopt: xformopt)
      expect(result).to eq(expected)
    end
  end
end

