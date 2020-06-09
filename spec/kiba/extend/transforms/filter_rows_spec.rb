require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::FilterRows do
  describe 'FieldEqualTo' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'in_set'],
      ['1', 'N'],
      ['2', 'Y']
    ]
    
    before { generate_csv(test_csv, rows) }
    it 'keeps row based on given field value match' do
      result = execute_job(filename: test_csv, xform: FilterRows::FieldEqualTo, xformopt: {action: :keep, field: :id, value: '1'})
      expect(result).to be_a(Array)
      expect(result.size).to eq(1)
      expect(result[0][:id]).to eq('1')
    end
    it 'rejects row based on given field value match' do
      result = execute_job(filename: test_csv, xform: FilterRows::FieldEqualTo, xformopt: {action: :reject, field: :in_set, value: 'N'})
      expect(result).to be_a(Array)
      expect(result.size).to eq(1)
      expect(result[0][:id]).to eq('2')
    end
    after { File.delete(test_csv) if File.exist?(test_csv) }
  end

  describe 'FieldMatchRegexp' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'occ'],
      ['1', 'farmer;'],
      ['2', 'farmer']
    ]
    
    before { generate_csv(test_csv, rows) }
    after { File.delete(test_csv) if File.exist?(test_csv) }

    it 'keeps row based on given field value match' do
      result = execute_job(filename: test_csv, xform: FilterRows::FieldMatchRegexp, xformopt: {action: :keep, field: :occ, match: '; *$'})
      expect(result).to be_a(Array)
      expect(result.size).to eq(1)
      expect(result[0][:id]).to eq('1')
    end
    it 'rejects row based on given field value match' do
      result = execute_job(filename: test_csv, xform: FilterRows::FieldMatchRegexp, xformopt: {action: :reject, field: :occ, match: '; *$'})
      expect(result).to be_a(Array)
      expect(result.size).to eq(1)
      expect(result[0][:id]).to eq('2')
    end
  end
  
  describe 'FieldPopulated' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'val'],
      ['1', ''],
      ['2', 'Y']
    ]
    
    before { generate_csv(test_csv, rows) }
    context 'when action: keep' do
      it 'keeps row if given field is populated' do
        result = execute_job(filename: test_csv,
                             xform: FilterRows::FieldPopulated,
                             xformopt: {action: :keep, field: :val})
        expect(result).to be_a(Array)
        expect(result.size).to eq(1)
        expect(result[0][:id]).to eq('2')
      end
    end
    context 'when action: reject' do
      it 'rejects row if given field is populated' do
        result = execute_job(filename: test_csv,
                             xform: FilterRows::FieldPopulated,
                             xformopt: {action: :reject, field: :val})
        expect(result).to be_a(Array)
        expect(result.size).to eq(1)
        expect(result[0][:id]).to eq('1')
      end
      after { File.delete(test_csv) if File.exist?(test_csv) }
    end
  end
end
