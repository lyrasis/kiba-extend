require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Deduplicate do
  describe 'MultiFieldValues' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['val'],
      ['1;1;1;2;2;2'],
      [''],
      ['1'],
      [1]
    ]
    before do
      generate_csv(test_csv, rows)
    end
    it 'removes duplicate values in one field (NOT safe for fieldgroups)' do
      expected = [
        {:val=>'1;2'},
        {:val=>''},
        {:val=>'1'},
        {:val=>'1'}
      ]
      result = execute_job(filename: test_csv,
                           xform: Deduplicate::MultiFieldValues,
                           xformopt: {field: :val, sep: ';'})
      expect(result).to eq(expected)
    end
  end
end

