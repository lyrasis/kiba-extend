# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Helpers::FieldEvennessChecker do
  subject(:checker){ described_class.new(valhash) }

  describe '#call' do
    let(:result){ checker.call }
    
    context 'with even field values' do
      let(:valhash) do
        {
          foo: {
            a: %w[a f o],
            b: %w[b foo],
            c: ['%NULLVALUE%']
          },
          bar: {
            a: %w[a a a],
            b: ['b', '%NULLVALUE%'],
            c: %w[c]
          }
        }
      end

      it 'returns :even' do
        expect(result).to eq(:even)
      end
    end

    context 'with uneven field values' do
      let(:valhash) do
        {
          foo: {
            a: %w[a f o],
            b: %w[b foo],
            c: ['%NULLVALUE%']
          },
          bar: {
            a: %w[a],
            b: ['b', '%NULLVALUE%'],
            c: %w[c bar]
          }
        }
      end

      it 'returns array of uneven sources' do
        expect(result).to eq(%i[a c])
      end
    end
  end
end
