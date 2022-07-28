# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Clean do

  describe 'DelimiterOnlyFields' do
    let(:rows) do
      [
        %w[id in_set],
        ['1', 'a; b'],
        ['2', ';'],
        ['3', nil],
        ['4', '%NULLVALUE%;%NULLVALUE%;%NULLVALUE%']
      ]
    end
    let(:result) { execute_job(filename: test_csv, xform: Clean::DelimiterOnlyFields, xformopt: options) }

    before { generate_csv(rows) }
    after { File.delete(test_csv) if File.exist?(test_csv) }

    context 'when use_nullvalue = false (the default)' do
      let(:options) { { delim: ';' } }
      it 'changes delimiter only fields to nil' do
        expect(result[1][:in_set]).to be_nil
      end
      it 'leaves other fields unchanged' do
        expect(result[0][:in_set]).to eq('a; b')
        expect(result[2][:in_set]).to be_nil
        expect(result[3][:in_set]).to eq('%NULLVALUE%;%NULLVALUE%;%NULLVALUE%')
      end
    end

    context 'when use_nullvalue = true' do
      let(:options) { { delim: ';', use_nullvalue: true } }
      it 'changes delimiter only fields to nil' do
        expect(result[1][:in_set]).to be_nil
        expect(result[3][:in_set]).to be_nil
      end
      it 'leaves other fields unchanged' do
        expect(result[0][:in_set]).to eq('a; b')
        expect(result[2][:in_set]).to be_nil
      end
    end
  end

end
