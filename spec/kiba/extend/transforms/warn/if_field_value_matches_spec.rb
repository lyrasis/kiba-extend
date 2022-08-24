# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Warn::IfFieldValueMatches do
  subject(:xform){ described_class.new(**params) }
  let(:field){ :test }
  let(:delim){ '|' }
  
  describe '#process' do
    let(:result){ xform.process(row) }

    context 'with string value' do
      let(:match){ 'UNMAPPED' }

      context 'when no delim (single value)' do
        let(:params){ {field: field, match: match} }
        
        context 'without value match' do
          let(:row){ {test: 'value'} }

          it 'returns row and does not warn' do
            expect(result).to eq(row)
            expect(xform).not_to receive(:warn)
          end
        end

        context 'with value match' do
          let(:row){ {test: 'UNMAPPED'} }
          
          it 'warns and returns row' do
            expect(xform).to receive(:warn)
            expect(result).to eq(row)
          end
        end
      end

      context 'when delim (multi value)' do
        let(:params){ {field: field, match: match, delim: delim} }
        
        context 'without value match' do
          let(:row){ {test: 'value|another'} }

          it 'returns row and does not warn' do
            expect(result).to eq(row)
            expect(xform).not_to receive(:warn)
          end
        end

        context 'with value match' do
          let(:row){ {test: 'nonmatch|UNMAPPED'} }
          
          it 'warns and returns row' do
            expect(xform).to receive(:warn)
            expect(result).to eq(row)
          end
        end
      end
    end

    context 'with regex value' do
      let(:match){ '^fo+$' }

      context 'when no delim (single value)' do
        let(:params){ {field: field, match: match, matchmode: :regex} }
        
        context 'without value match' do
          let(:row){ {test: 'food'} }

          it 'returns row and does not warn' do
            expect(result).to eq(row)
            expect(xform).not_to receive(:warn)
          end
        end

        context 'with value match' do
          let(:row){ {test: 'foo'} }
          
          it 'warns and returns row' do
            expect(xform).to receive(:warn)
            expect(result).to eq(row)
          end
        end
      end

      context 'when delim (multi value)' do
        let(:params){ {field: field, match: match, delim: delim, matchmode: :regex} }
        
        context 'without value match' do
          let(:row){ {test: 'food|another'} }

          it 'returns row and does not warn' do
            expect(result).to eq(row)
            expect(xform).not_to receive(:warn)
          end
        end

        context 'with value match' do
          let(:row){ {test: 'nonmatch|foo|bar'} }
          
          it 'warns and returns row' do
            expect(xform).to receive(:warn)
            expect(result).to eq(row)
          end
        end
      end
    end
  end
end
