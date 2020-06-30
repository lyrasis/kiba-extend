require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Explode do
  describe 'RowsFromMultivalField' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'r1', 'r2'],
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
          { id: '001', r1: 'b', r2: 'foo;bar' },
        ]
        result = execute_job(filename: test_csv,
                             xform: Explode::RowsFromMultivalField,
                             xformopt: {field: :r1, delim: ';'}
                            )
        expect(result).to eq(expected)
      end
    end
  end

  describe 'ColumnsRemappedInNewRows' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'r1', 'r2', 'ra', 'rb', 'xq'],
      ['001', 'a;b', 'foo;bar', 'aa', 'bb', 'eee']
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
          { id: '001', a1: 'a;b', a2: 'foo;bar', xq: 'eee' },
          { id: '001', a1: 'aa', a2: 'bb', xq: 'eee' },
        ]
        result = execute_job(filename: test_csv,
                             xform: Explode::ColumnsRemappedInNewRows,
                             xformopt: { remap_groups: [
                                                         %i[r1 r2],
                                                         %i[ra rb]
                                                       ],
                                        map_to: %i[a1 a2]
                                       }
                            )
        expect(result).to eq(expected)
      end
    end
  end
end

