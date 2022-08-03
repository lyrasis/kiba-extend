# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::FieldValueMatcher do
  subject(:xform){ described_class.new(**params) }
  let(:field){ :test }
  let(:delim){ '|' }
  let(:params){ {field: field, match: match} }
  let(:match){ 'UNMAPPED' }
  
  describe '#call' do
    let(:result){ xform.call(row) }

    context 'when field not in given data' do
      let(:row){ {foo: 'bar'} }

      it 'returns false' do
        expect(result).to be false
      end
    end
    
    context 'when field value nil' do
      let(:row){ {test: nil} }

      it 'returns false' do
        expect(result).to be false
      end
    end

    context 'when field value empty and match value not empty' do
      let(:row){ {test: ''} }

      it 'returns false' do
        expect(result).to be false
      end
    end

    context 'when field value empty and match value empty' do
      let(:row){ {test: ''} }
      let(:match){ '' }

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'when field value empty and match value empty and multivalue and regexp' do
      let(:row){ {test: 'foo|'} }
      let(:match){ '^$' }
      let(:params){ {field: field, match: match, matchmode: :regex, delim: delim} }

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'when field value empty and match value empty and multivalue and treat_as_null' do
      let(:row){ {test: 'foo|%NULL%|bar'} }
      let(:match){ '' }
      let(:params){ {field: field, match: match, delim: delim, treat_as_null: '%NULL%'} }

      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'without value match' do
      let(:row){ {test: 'value'} }

      it 'returns false' do
        expect(result).to be false
      end
    end

    context 'with value match' do
      let(:row){ {test: 'UNMAPPED'} }
      
      it 'returns true' do
        expect(result).to be true
      end
    end

    context 'when delim (multi value)' do
      let(:params){ {field: field, match: match, delim: delim} }
      
      context 'without value match' do
        let(:row){ {test: 'value|another'} }

        it 'returns false' do
          expect(result).to be false
        end
      end

      context 'with value match' do
        let(:row){ {test: 'nonmatch|UNMAPPED'} }
        
        it 'returns true' do
          expect(result).to be true
        end
      end
    end


    context 'with regex value' do
      let(:match){ '^fo+$' }

      context 'when no delim (single value)' do
        let(:params){ {field: field, match: match, matchmode: :regex} }
        
        context 'without value match' do
          let(:row){ {test: 'food'} }

          it 'returns false' do
            expect(result).to be false
          end
        end

        context 'with value match' do
          let(:row){ {test: 'foo'} }
          
          it 'returns true' do
            expect(result).to be true
          end
        end
      end

      context 'when delim (multi value)' do
        let(:params){ {field: field, match: match, delim: delim, matchmode: :regex} }
        
        context 'without value match' do
          let(:row){ {test: 'food|another'} }

          it 'returns false' do
            expect(result).to be false
          end
        end

        context 'with value match' do
          let(:row){ {test: 'nonmatch|foo|bar'} }
          
          it 'returns true' do
            expect(result).to be true
          end
        end
      end
    end
  end
end
