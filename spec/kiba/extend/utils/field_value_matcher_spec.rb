# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::FieldValueMatcher do
  subject(:xform){ described_class.new(**params) }
  
  describe '#call' do
    let(:result){ xform.call(row) }
    let(:results){ expectations.keys.map{ |row| xform.call(row) } }
    let(:expected){ expectations.values }

    context %{with field: :test, match: 'UNMAPPED'} do
      let(:params){ {field: :test, match: 'UNMAPPED'} }
      let(:expectations) do
        {
          {foo: 'bar'} => false, # field not present, always false
          {test: nil} => false, # nil field value, always false
          {test: ''} => false,
          {test: 'UNMAPPED'} => true,
          {test: 'UNMAPPED '} => true, # values are stripped
          {test: '  UNMAPPED '} => true, # values are stripped
          {test: 'Unmapped'} => false
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{with field: :test, match: 'UNMAPPED', strip: false} do
      let(:params){ {field: :test, match: 'UNMAPPED', strip: false} }
      let(:expectations) do
        {
          {test: 'UNMAPPED'} => true,
          {test: 'UNMAPPED '} => false, # values are not stripped
          {test: '  UNMAPPED '} => false, # values are not stripped
          {test: 'Unmapped'} => false
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{with field: :test, match: 'UNMAPPED', casesensitive: false} do
      let(:params){ {field: :test, match: 'UNMAPPED', casesensitive: false} }
      let(:expectations) do
        {
          {test: 'UNMAPPED'} => true,
          {test: 'Unmapped'} => true
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{with field: :test, match: ''} do
      let(:params){ {field: :test, match: ''} }
      let(:expectations) do
        {
          {foo: 'bar'} => false,
          {test: nil} => true,
          {test: ''} => true,
          {test: ' '} => true, # values are stripped
          {test: '    '} => true, # values are stripped
          {test: 'UNMAPPED'} => false
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{with field: :test, match: '', treat_as_null: '%NULL%'} do
      let(:params){ {field: :test, match: '', treat_as_null: '%NULL%'} }
      let(:expectations) do
        {
          {foo: 'bar'} => false,
          {test: nil} => true,
          {test: ''} => true,
          {test: 'UNMAPPED'} => false,
          {test: '%NULL%'} => true, # gets converted to empty value prior to matching
          {test: ' %NULL% '} => true # gets converted to empty value prior to matching
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{with field: :test, match: '^$', treat_as_null: '%NULL%', matchmode: :regexp} do
      let(:params){ {field: :test, match: '^$', treat_as_null: '%NULL%', matchmode: :regexp} }
      let(:expectations) do
        {
          {foo: 'bar'} => false,
          {test: nil} => true,
          {test: ''} => true,
          {test: 'UNMAPPED'} => false,
          {test: '%NULL%'} => true
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{when field: :test, match: match, delim: '|'} do
      let(:params){ {field: :test, match: 'Foo', delim: '|'} }
      let(:expectations) do
        {
          {foo: 'Foo'} => false,
          {test: nil} => false,
          {test: ''} => false,
          {test: 'Foo'} => true,
          {test: 'foo'} => false,
          {test: 'Foo|bar'} => true,
          {test: 'baz|Foo'} => true,
          {test: ' Foo|bar'} => true,
          {test: 'baz| Foo '} => true,
          {test: '|Foo'} => true,
          {test: 'Foo|'} => true,
          {test: 'foo|'} => false,
          {test: 'bar|baz'} => false
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{when field: :test, match: match, delim: '|', multimode: :all} do
      let(:params){ {field: :test, match: 'Foo', delim: '|', multimode: :all} }
      let(:expectations) do
        {
          {foo: 'Foo'} => false,
          {test: nil} => false,
          {test: ''} => false,
          {test: 'Foo'} => true,
          {test: 'foo'} => false,
          {test: 'Foo|Foo'} => true,
          {test: 'Foo|bar'} => false,
          {test: 'baz|Foo'} => false,
          {test: ' Foo|bar'} => false,
          {test: 'baz| Foo '} => false,
          {test: '|Foo'} => true,
          {test: 'Foo|'} => true,
          {test: 'foo|'} => false,
          {test: 'bar|baz'} => false
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{when field: :test, match: match, delim: '|', multimode: :allstrict} do
      let(:params){ {field: :test, match: 'Foo', delim: '|', multimode: :allstrict} }
      let(:expectations) do
        {
          {foo: 'Foo'} => false,
          {test: nil} => false,
          {test: ''} => false,
          {test: 'Foo'} => true,
          {test: 'foo'} => false,
          {test: 'Foo|Foo'} => true,
          {test: 'Foo|bar'} => false,
          {test: 'baz|Foo'} => false,
          {test: ' Foo|bar'} => false,
          {test: 'baz| Foo '} => false,
          {test: '|Foo'} => false,
          {test: 'Foo|'} => false,
          {test: 'foo|'} => false,
          {test: 'bar|baz'} => false
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end
    
    context %{when field: :test, match: '^$', matchmode: :regex, delim: '|'} do
      let(:params){ {field: :test, match: '^$', matchmode: :regex, delim: '|'} }
      let(:expectations) do
        {
          {test: 'foo|'} => true,
          {test: 'foo||foo'} => true,
          {test: 'foo| |foo'} => true,
          {test: '|foo'} => true,
          {test: 'foo|%NULL%'} => false,
          {test: 'foo|%NULL%|foo'} => false,
          {test: 'foo| %NULL%|foo'} => false,
          {test: '%NULL%|foo'} => false,
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{when field: :test, match: '', delim: '|', treat_as_null: '%NULL%'} do
      let(:params){ {field: :test, match: '', delim: '|', treat_as_null: '%NULL%'} }
      let(:expectations) do
        {
          {test: ''} => true,
          {test: '%NULL%'} => true,
          {test: nil} => true,
          {test: 'foo|%NULL%|bar'} => true,
          {test: 'foo||bar'} => true,
          {test: 'foo| %NULL% |bar'} => true,
          {test: 'foo|  |bar'} => true
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{when field: :test, match: '', delim: '|', treat_as_null: '%NULL%', strip: false} do
      let(:params){ {field: :test, match: '', delim: '|', treat_as_null: '%NULL%', strip: false} }
      let(:expectations) do
        {
          {test: 'foo|%NULL%|bar'} => true,
          {test: 'foo||bar'} => true,
          {test: 'foo| %NULL% |bar'} => false,
          {test: 'foo|  |bar'} => false
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end


    context %{with field: :test, match: '^fo+$', matchmode: :regex} do
      let(:params){ {field: :test, match: '^fo+$', matchmode: :regex} }
      let(:expectations) do
        {
          {test: 'food'} => false,
          {test: 'foo'} => true,
          {test: ' foo '} => true, # becasue stripped
          {test: 'Food'} => false,
          {test: 'Foo'} => false,
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{with field: :test, match: '^fo+$', matchmode: :regex, delim: '|'} do
      let(:params){ {field: :test, match: '^fo+$', matchmode: :regex, delim: '|'} }
      let(:expectations) do
        {
          {test: 'foo'} => true,
          {test: 'foo|bar'} => true,
          {test: 'Foo|bar'} => false,
          {test: 'drink|food'} => false
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end

    context %{with field: :test, match: '^fo+', matchmode: :regex, delim: '|', casesensitive: false} do
      let(:params){ {field: :test, match: '^fo+', matchmode: :regex, delim: '|', casesensitive: false} }
      let(:expectations) do
        {
          {test: 'foo'} => true,
          {test: 'foo|bar'} => true,
          {test: 'Foo|bar'} => true,
          {test: 'drink|food'} => true
        }
      end

      it 'returns expected' do
        expect(results).to eq(expected)
      end
    end
  end
end
