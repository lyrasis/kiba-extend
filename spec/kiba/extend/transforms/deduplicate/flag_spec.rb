# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Deduplicate::Flag do
  subject(:xform){ described_class.new(**params) }
  let(:params){ {on_field: onfield, in_field: infield, using: deduper} }
  let(:onfield){ :id }
  let(:infield){ :d }
  let(:deduper){ {} }
  let(:result){ input.map{ |row| xform.process(row) } }

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
        { id: '1', x: 'a', d: 'n' },
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
    let(:params){ {on_field: onfield, in_field: infield, using: deduper, explicit_no: false} }
    let(:expected) do
      [
          { id: '1', x: 'a', d: '' },
          { id: '2', x: 'a', d: '' },
          { id: '1', x: 'b', d: 'y' },
          { id: '3', x: 'b', d: '' }
      ]
    end
    
    it 'deduplicates indicates non-duplicates with blank' do
      expect(result).to eq(expected)
    end
  end

  context 'without `using` hash' do
    let(:deduper){ nil }
    it 'raises error' do
      expect{ xform }.to raise_error(Kiba::Extend::Transforms::Deduplicate::Flag::NoUsingValueError)
    end
  end

end
