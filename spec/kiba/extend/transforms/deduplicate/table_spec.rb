# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Deduplicate::Table do
  subject(:xform){ described_class.new(**params) }
  let(:params){ {field: field} }
  let(:field){ :combined }
  let(:result) do
    Kiba::StreamingRunner.transform_stream(input, xform)
      .map{ |row| row }
  end

  let(:input) do
    [
      {foo: 'a', bar: 'b', baz: 'f', combined: 'a b'},
      {foo: 'c', bar: 'd', baz: 'g', combined: 'c d'},
      {foo: 'c', bar: 'e', baz: 'h', combined: 'c e'},
      {foo: 'c', bar: 'd', baz: 'i', combined: 'c d'},
    ]
  end

  context 'when keeping deduplication field' do
    let(:field){ :foo }
    let(:expected) do
      [
        {foo: 'a', bar: 'b', baz: 'f', combined: 'a b'},
        {foo: 'c', bar: 'd', baz: 'g', combined: 'c d'}
      ]
    end
    
    it 'deduplicates table, retaining field' do
      expect(result).to eq(expected)
    end
  end

  context 'when deleting deduplication field' do
    let(:params){ {field: field, delete_field: true} }
    let(:field){ :combined }
    let(:expected) do
      [
        {foo: 'a', bar: 'b', baz: 'f'},
        {foo: 'c', bar: 'd', baz: 'g'},
        {foo: 'c', bar: 'e', baz: 'h'}
      ]
    end
    
    it 'deduplicates indicates non-duplicates with blank' do
      expect(result).to eq(expected)
    end
  end
end
