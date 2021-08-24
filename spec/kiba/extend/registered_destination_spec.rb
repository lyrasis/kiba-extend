# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Kiba::Extend::RegisteredDestination' do
  let(:filekey){ :fkey }
  let(:path){ File.join('spec', 'fixtures', 'fkey.csv') }
  let(:default){ { path: path } }
  let(:default_desc){ { path: path, desc: 'description' } }
  let(:dest){ Kiba::Extend::RegisteredDestination.new(key: filekey, data: data) }

  describe '#args' do
    let(:result){ dest.args }
    context 'with basic defaults' do
      let(:data){ default }
      let(:expected) do
        {filename: path, options: Kiba::Extend.csvopts}
      end
      it 'returns Kiba::Extend default destination class' do
        expect(result).to eq(expected)
      end
    end

    context 'with given options' do
      let(:override_opts){ {foo: :bar} }
      let(:data){ { path: path, dest_opt: override_opts  } }
      let(:expected) do
        {filename: path, options: override_opts}
      end
      it 'returns Kiba::Extend default destination class' do
        expect(result).to eq(expected)
      end
    end
  end

  describe '#description' do
    let(:result){ dest.description }
    context 'when not given' do
      let(:data){ default }
      it 'returns empty string' do
        expect(result).to eq('')
      end
    end

    context 'when given' do
      let(:data){ default_desc }
      it 'returns given value' do
        expect(result).to eq('description')
      end
    end
  end

  describe '#klass' do
    let(:result){ dest.klass }
    context 'with basic defaults' do    
      let(:data){ default }
      it 'returns Kiba::Extend default destination class' do
        expect(result).to eq(Kiba::Extend.destination)
      end
    end

    context 'with a given class' do    
      let(:override_klass){ Kiba::Common::Sources::CSV }
      let(:data){ { path: path, dest_class: override_klass  } }
      it 'returns Kiba::Extend default destination class' do
        expect(result).to eq(override_klass)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
