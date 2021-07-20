# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Explode do
  describe 'RowsFromMultivalField' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[id r1 r2],
      ['001', 'a;b', 'foo;bar']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    after do
      File.delete(test_csv) if File.exist?(test_csv)
      File.delete('tmp/lkp.csv') if File.exist?('tmp/lkp.csv')
    end

    context 'when given field :r1 and delim \';\'' do
      it 'creates 2 rows with same :id and :r2 fields' do
        expected = [
          { id: '001', r1: 'a', r2: 'foo;bar' },
          { id: '001', r1: 'b', r2: 'foo;bar' }
        ]
        result = execute_job(filename: test_csv,
                             xform: Explode::RowsFromMultivalField,
                             xformopt: { field: :r1, delim: ';' })
        expect(result).to eq(expected)
      end
    end
  end

  describe 'ColumnsRemappedInNewRows' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[f1 c1 f2 c2 season f3],
      %w[strawberry red blueberry blue spring cherry],
      ['fig;honeydew', 'brown;green', 'watermelon', 'green', 'summer', nil],
      [nil, nil, nil, nil, 'winter', 'grapefruit'],
      [nil, nil, nil, nil, 'autumn', nil]
    ]

    before do
      generate_csv(test_csv, rows)
    end
    after do
      File.delete(test_csv) if File.exist?(test_csv)
      File.delete('tmp/lkp.csv') if File.exist?('tmp/lkp.csv')
    end

    it 'creates expected result' do
      expected = [
        { fruit: 'strawberry', color: 'red', season: 'spring' },
        { fruit: 'blueberry', color: 'blue', season: 'spring' },
        { fruit: 'cherry', color: nil, season: 'spring' },
        { fruit: 'fig;honeydew', color: 'brown;green', season: 'summer' },
        { fruit: 'watermelon', color: 'green', season: 'summer' },
        { fruit: 'grapefruit', color: nil, season: 'winter' },
        { fruit: nil, color: nil, season: 'autumn' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Explode::ColumnsRemappedInNewRows,
                           xformopt: { remap_groups: [
                             %i[f1 c1],
                             %i[f2 c2],
                             %i[f3]
                           ],
                                       map_to: %i[fruit color] })
      expect(result).to eq(expected)
    end
  end

  describe 'FieldValuesToNewRows' do
    test_csv = 'tmp/test.csv'
    rows = [
      %w[id child parent],
      [1, 'a;b', 'c;d'],
      [2, 'a', 'b'],
      [3, '', 'q'],
      [4, 'n', nil],
      [5, '', nil],
      [6, 'p;', ';z'],
      [7, 'm;;n', 's']
    ]
    before do
      generate_csv(test_csv, rows)
    end

    context 'when multival = true' do
      context 'when keep_nil and keep_empty= false' do
        it 'reshapes the columns as specified' do
          expected = [
            { id: '1', val: 'a' },
            { id: '1', val: 'b' },
            { id: '1', val: 'c' },
            { id: '1', val: 'd' },
            { id: '2', val: 'a' },
            { id: '2', val: 'b' },
            { id: '3', val: 'q' },
            { id: '4', val: 'n' },
            { id: '6', val: 'p' },
            { id: '6', val: 'z' },
            { id: '7', val: 'm' },
            { id: '7', val: 'n' },
            { id: '7', val: 's' }
          ]
          result = execute_job(filename: test_csv,
                               xform: Explode::FieldValuesToNewRows,
                               xformopt: { fields: %i[child parent],
                                           target: :val,
                                           multival: true,
                                           sep: ';' })
          expect(result).to eq(expected)
        end
      end
      context 'when keep_nil = true' do
        it 'reshapes the columns as specified' do
          expected = [
            { id: '1', val: 'a' },
            { id: '1', val: 'b' },
            { id: '1', val: 'c' },
            { id: '1', val: 'd' },
            { id: '2', val: 'a' },
            { id: '2', val: 'b' },
            { id: '3', val: 'q' },
            { id: '4', val: 'n' },
            { id: '4', val: nil },
            { id: '5', val: nil },
            { id: '6', val: 'p' },
            { id: '6', val: 'z' },
            { id: '7', val: 'm' },
            { id: '7', val: 'n' },
            { id: '7', val: 's' }
          ]
          result = execute_job(filename: test_csv,
                               xform: Explode::FieldValuesToNewRows,
                               xformopt: { fields: %i[child parent],
                                           target: :val,
                                           multival: true,
                                           sep: ';',
                                           keep_nil: true })
          expect(result).to eq(expected)
        end
      end

      context 'when keep_empty = true' do
        it 'reshapes the columns as specified' do
          expected = [
            { id: '1', val: 'a' },
            { id: '1', val: 'b' },
            { id: '1', val: 'c' },
            { id: '1', val: 'd' },
            { id: '2', val: 'a' },
            { id: '2', val: 'b' },
            { id: '3', val: '' },
            { id: '3', val: 'q' },
            { id: '4', val: 'n' },
            { id: '5', val: '' },
            { id: '6', val: 'p' },
            { id: '6', val: '' },
            { id: '6', val: '' },
            { id: '6', val: 'z' },
            { id: '7', val: 'm' },
            { id: '7', val: '' },
            { id: '7', val: 'n' },
            { id: '7', val: 's' }
          ]
          result = execute_job(filename: test_csv,
                               xform: Explode::FieldValuesToNewRows,
                               xformopt: { fields: %i[child parent],
                                           target: :val,
                                           multival: true,
                                           sep: ';',
                                           keep_empty: true })
          expect(result).to eq(expected)
        end
      end
    end

    context 'when multival = false' do
      context 'when keep_nil and keep_empty = false' do
        it 'reshapes the columns as specified' do
          expected = [
            { id: '1', val: 'a;b' },
            { id: '1', val: 'c;d' },
            { id: '2', val: 'a' },
            { id: '2', val: 'b' },
            { id: '3', val: 'q' },
            { id: '4', val: 'n' },
            { id: '6', val: 'p;' },
            { id: '6', val: ';z' },
            { id: '7', val: 'm;;n' },
            { id: '7', val: 's' }
          ]
          result = execute_job(filename: test_csv,
                               xform: Explode::FieldValuesToNewRows,
                               xformopt: { fields: %i[child parent],
                                           target: :val })
          expect(result).to eq(expected)
        end
      end

      context 'when keep_nil and keep_empty = true' do
        it 'reshapes the columns as specified' do
          expected = [
            { id: '1', val: 'a;b' },
            { id: '1', val: 'c;d' },
            { id: '2', val: 'a' },
            { id: '2', val: 'b' },
            { id: '3', val: '' },
            { id: '3', val: 'q' },
            { id: '4', val: 'n' },
            { id: '4', val: nil },
            { id: '5', val: '' },
            { id: '5', val: nil },
            { id: '6', val: 'p;' },
            { id: '6', val: ';z' },
            { id: '7', val: 'm;;n' },
            { id: '7', val: 's' }
          ]
          result = execute_job(filename: test_csv,
                               xform: Explode::FieldValuesToNewRows,
                               xformopt: { fields: %i[child parent],
                                           target: :val,
                                           keep_nil: true,
                                           keep_empty: true })
          expect(result).to eq(expected)
        end
      end
    end
  end
end
