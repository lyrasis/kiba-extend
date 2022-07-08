# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Helpers::FieldEvennessFixer do
  subject(:fixer){ described_class.new(valhash) }

  describe '#call' do
    let(:result){ fixer.call }
    

    let(:valhash) do
      {
        foo: {
          a: %w[a f],
          b: %w[bf],
          c: ['%NULLVALUE%'],
          d: %w[d f],
          e: ['%NULLVALUE%']
        },
        bar: {
          a: %w[a],
          b: %w[b],
          c: %w[c],
          d: ['%NULLVALUE%'],
          e: ['%NULLVALUE%']
        }
      }
    end

    let(:expected) do
      {
        foo: {
          a: %w[a f],
          b: %w[bf],
          c: ['%NULLVALUE%'],
          d: %w[d f],
          e: ['%NULLVALUE%']
        },
        bar: {
          a: ['a', '%NULLVALUE%'],
          b: %w[b],
          c: %w[c],
          d: ['%NULLVALUE%', '%NULLVALUE%'],
          e: ['%NULLVALUE%']
        }
      }
    end

    it 'returns evened valhash' do
      expect(result).to eq(expected)
    end
  end
end

