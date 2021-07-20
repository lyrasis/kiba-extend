require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Deduplicate do
  describe 'Fields' do
    context 'when casesensitive = true' do
      it 'removes value(s) of source field from target field(s)' do
        test_csv = 'tmp/test.csv'
        rows = [
          %w[x y z],
          %w[a a b],
          ['a', 'a ', 'a'],
          ['a', 'b;a', 'a;c'],
          ['a;b', 'b;a', 'a;c'],
          %w[a aa bat],
          [nil, 'a', nil],
          ['', ' ;a', 'b;'],
          ['a', nil, nil],
          %w[a A a]
        ]
        generate_csv(test_csv, rows)
        expected = [
          { x: 'a', y: nil, z: 'b' },
          { x: 'a', y: nil, z: nil },
          { x: 'a', y: 'b', z: 'c' },
          { x: 'a;b', y: nil, z: 'c' },
          { x: 'a', y: 'aa', z: 'bat' },
          { x: nil, y: 'a', z: nil },
          { x: '', y: 'a', z: 'b' },
          { x: 'a', y: nil, z: nil },
          { x: 'a', y: 'A', z: nil }
        ]
        result = execute_job(filename: test_csv,
                             xform: Deduplicate::Fields,
                             xformopt: { source: :x, targets: %i[y z], multival: true, sep: ';' })
        expect(result).to eq(expected)
      end
    end
    context 'when casesensitive = false' do
      it 'removes value(s) of source field from target field(s)' do
        test_csv = 'tmp/test.csv'
        rows = [
          %w[x y z],
          %w[a A a],
          %w[a a B]
        ]
        generate_csv(test_csv, rows)
        expected = [
          { x: 'a', y: nil, z: nil },
          { x: 'a', y: nil, z: 'B' }
        ]
        result = execute_job(filename: test_csv,
                             xform: Deduplicate::Fields,
                             xformopt: { source: :x, targets: %i[y z], multival: false,
                                         casesensitive: false })
        expect(result).to eq(expected)
      end
    end
  end

  describe 'FieldValues' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[val x],
      ['1;1;1;2;2;2', 'a;A;b;b;b'],
      ['', 'q;r;r'],
      %w[1 2],
      [1, 2]
    ]
    before do
      generate_csv(test_csv, rows)
    end
    it 'removes duplicate values in one field (NOT safe for fieldgroups)' do
      expected = [
        { val: '1;2', x: 'a;A;b' },
        { val: '', x: 'q;r' },
        { val: '1', x: '2' },
        { val: '1', x: '2' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Deduplicate::FieldValues,
                           xformopt: { fields: %i[val x], sep: ';' })
      expect(result).to eq(expected)
    end
  end

  describe 'Flag' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[id x],
      %w[1 a],
      %w[2 a],
      %w[1 b],
      %w[3 b]
    ]
    before do
      generate_csv(test_csv, rows)
      @deduper = {}
    end
    it 'adds column with y/n to indicate duplicate records' do
      expected = [
        { id: '1', x: 'a', d: 'n' },
        { id: '2', x: 'a', d: 'n' },
        { id: '1', x: 'b', d: 'y' },
        { id: '3', x: 'b', d: 'n' }
      ]
      opt = {
        on_field: :id,
        in_field: :d,
        using: @deduper
      }
      result = execute_job(filename: test_csv,
                           xform: Deduplicate::Flag,
                           xformopt: opt)
      expect(result).to eq(expected)
    end
  end

  describe 'GroupedFieldValues' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[name role],
      ['Fred;Freda;Fred;James', 'author;photographer;editor;illustrator'],
      [';', ';'],
      %w[1 2]
    ]
    before do
      generate_csv(test_csv, rows)
    end
    it 'removes duplicate values in one field, and removes corresponding fieldgroup values' do
      expected = [
        { name: 'Fred;Freda;James', role: 'author;photographer;illustrator' },
        { name: nil, role: nil },
        { name: '1', role: '2' }
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
