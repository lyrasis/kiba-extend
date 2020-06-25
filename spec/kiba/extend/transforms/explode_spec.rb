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
end

