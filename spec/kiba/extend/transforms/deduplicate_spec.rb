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

  describe 'Flag' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'x'],
      ['1', 'a'],
      ['2', 'a'],
      ['1', 'b'],
      ['3', 'b']
    ]
    before do
      generate_csv(test_csv, rows)
      @deduper = {}
    end
    it 'adds column with y/n to indicate duplicate records' do
      expected = [
        {:id=>'1', :x=>'a', :d=>'n'},
        {:id=>'2', :x=>'a', :d=>'n'},
        {:id=>'1', :x=>'b', :d=>'y'},
        {:id=>'3', :x=>'b', :d=>'n'}
      ]
      opt = {
        on_field: :id,
        in_field: :d,
        using: @deduper
      }
      result = execute_job(filename: test_csv,
                           xform: Deduplicate::Flag,
                           xformopt: opt
                          )
      expect(result).to eq(expected)
    end
  end

  describe 'GroupedFieldValues' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['name', 'role'],
      ['Fred;Freda;Fred;James', 'author;photographer;editor;illustrator'],
      [';', ';'],
      ['1', '2']
    ]
    before do
      generate_csv(test_csv, rows)
    end
    it 'removes duplicate values in one field, and removes corresponding fieldgroup values' do
      expected = [
        {name: 'Fred;Freda;James', role: 'author;photographer;illustrator'},
        {name: nil, role: nil},
        {name: '1', role: '2'}
      ]
      result = execute_job(filename: test_csv,
                           xform: Deduplicate::GroupedFieldValues,
                           xformopt: {
                             on_field: :name,
                             grouped_fields: %i[role],
                             sep: ';'
                           })
      expect(result).to eq(expected)
    end
  end
end

