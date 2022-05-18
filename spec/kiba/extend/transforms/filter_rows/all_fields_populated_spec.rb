# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::FilterRows::AllFieldsPopulated do
  let(:fields){ %i[a b] }
  let(:input) do
    [
      {a: 'a', b: 'b', c: 'c' },
      {a: 'a', b: 'b', c: '' },
      {a: '', b: nil, c: 'c' },
      {a: '', b: 'b', c: 'c' },
      {a: '', b: nil, c: nil },
    ]
  end
  let(:transform){ described_class.new(action: action, fields: fields) }
  let(:result){ input.map{ |row| transform.process(row) }.compact }

  context 'with action: :keep' do
    let(:action){ :keep }
    let(:expected) do
      [
        {a: 'a', b: 'b', c: 'c' },
        {a: 'a', b: 'b', c: '' }
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
    
    context 'with fields: :all' do
      let(:fields){ :all }
      let(:expected) do
        [
          {a: 'a', b: 'b', c: 'c' }
        ]
      end
      
      it 'transforms as expected' do
        expect(result).to eq(expected)
      end
    end
  end

  context 'with action: :reject' do
    let(:action){ :reject }
    let(:expected) do
      [
        {a: '', b: nil, c: 'c' },
        {a: '', b: 'b', c: 'c' },
        {a: '', b: nil, c: nil }
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end
