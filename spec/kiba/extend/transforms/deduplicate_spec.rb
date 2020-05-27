require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Deduplicate do
  describe 'FieldValues' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['val', 'x'],
      ['1;1;1;2;2;2', 'a;A;b;b;b'],
      ['', 'q;r;r'],
      ['1', '2'],
      [1, 2]
    ]
    before do
      generate_csv(test_csv, rows)
    end
    it 'removes duplicate values in one field (NOT safe for fieldgroups)' do
      expected = [
        {:val=>'1;2', :x=>'a;A;b'},
        {:val=>'', :x=>'q;r'},
        {:val=>'1', :x=>'2'},
        {:val=>'1', :x=>'2'}
      ]
      result = execute_job(filename: test_csv,
                           xform: Deduplicate::FieldValues,
                           xformopt: {fields: [:val, :x], sep: ';'})
      expect(result).to eq(expected)
    end
  end
end

