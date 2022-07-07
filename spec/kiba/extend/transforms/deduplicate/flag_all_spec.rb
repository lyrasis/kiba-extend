# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Deduplicate::FlagAll do
  subject(:xform){ described_class.new(**params) }
  let(:params){ {on_field: onfield, in_field: infield} }
  let(:onfield){ :id }
  let(:infield){ :d }
  let(:result) do
    Kiba::StreamingRunner.transform_stream(input, xform)
      .map{ |row| row }
  end

  let(:input) do
    [
      {id: '1', x: 'a'},
      {id: '2', x: 'a'},
      {id: '1', x: 'b'},
      {id: '3', x: 'b'},
    ]
  end

  context 'with explicit no value = true' do
    let(:expected) do
      [
        { id: '1', x: 'a', d: 'y' },
        { id: '2', x: 'a', d: 'n' },
        { id: '1', x: 'b', d: 'y' },
        { id: '3', x: 'b', d: 'n' }
      ]
    end
    
    it 'deduplicates indicates non-duplicates with `n`' do
      expect(result).to eq(expected)
    end
  end

  context 'with explicit no value = false' do
    let(:params){ {on_field: onfield, in_field: infield, explicit_no: false} }
    let(:expected) do
      [
        { id: '1', x: 'a', d: 'y' },
        { id: '2', x: 'a', d: '' },
        { id: '1', x: 'b', d: 'y' },
        { id: '3', x: 'b', d: '' }
      ]
    end
    
    it 'deduplicates indicates non-duplicates with blank' do
      expect(result).to eq(expected)
    end
  end
end
