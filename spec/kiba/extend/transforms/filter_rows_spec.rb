# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::FilterRows do

  describe 'FieldMatchRegexp' do
    rows = [
      %w[id occ],
      ['1', 'farmer;'],
      %w[2 farmer]
    ]

    before { generate_csv(rows) }
    after { File.delete(test_csv) if File.exist?(test_csv) }

    it 'keeps row based on given field value match' do
      result = execute_job(filename: test_csv, xform: FilterRows::FieldMatchRegexp,
                           xformopt: { action: :keep, field: :occ, match: '; *$' })
      expect(result).to be_a(Array)
      expect(result.size).to eq(1)
      expect(result[0][:id]).to eq('1')
    end
    it 'rejects row based on given field value match' do
      result = execute_job(filename: test_csv, xform: FilterRows::FieldMatchRegexp,
                           xformopt: { action: :reject, field: :occ, match: '; *$' })
      expect(result).to be_a(Array)
      expect(result.size).to eq(1)
      expect(result[0][:id]).to eq('2')
    end
  end

  describe 'FieldPopulated' do
    rows = [
      %w[id val],
      ['1', ''],
      %w[2 Y]
    ]

    before { generate_csv(rows) }
    context 'when action: keep' do
      it 'keeps row if given field is populated' do
        result = execute_job(filename: test_csv,
                             xform: FilterRows::FieldPopulated,
                             xformopt: { action: :keep, field: :val })
        expect(result).to be_a(Array)
        expect(result.size).to eq(1)
        expect(result[0][:id]).to eq('2')
      end
    end
    context 'when action: reject' do
      it 'rejects row if given field is populated' do
        result = execute_job(filename: test_csv,
                             xform: FilterRows::FieldPopulated,
                             xformopt: { action: :reject, field: :val })
        expect(result).to be_a(Array)
        expect(result.size).to eq(1)
        expect(result[0][:id]).to eq('1')
      end
      after { File.delete(test_csv) if File.exist?(test_csv) }
    end
  end
end
