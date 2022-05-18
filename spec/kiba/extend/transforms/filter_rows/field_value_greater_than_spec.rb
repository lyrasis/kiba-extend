# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::FilterRows::FieldValueGreaterThan do
  let(:input) do
    [
      {a: 'a', b: 'b', c: 'c' },
      {a: 'a', b: 'd', c: '' },
      {a: '', b: 'b', c: 'c' }
    ]
  end
  let(:action){ :keep }
  let(:field){ :b }
  let(:value){ 'b' }
  let(:transform){ described_class.new(action: action, field: field, value: value) }
  let(:result){ input.map{ |row| transform.process(row) }.compact }

  it 'warns if called' do
    expect_any_instance_of(described_class).to receive(:warn)
    result
  end

  context 'with action: :keep' do
    let(:expected) do
      [
      {a: 'a', b: 'd', c: '' }
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with action: :reject' do
    let(:action){ :reject }
    let(:expected) do
      [
      {a: 'a', b: 'b', c: 'c' },
      {a: '', b: 'b', c: 'c' }
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end
