require 'spec_helper'

RSpec.describe Kiba::Extend::Fieldset do
  let(:rows) do
    [
      { a: 'aa', b: 'bb', c: 'cc', d: 'dd' },
      { a: 'aa', b: 'bee', c: 'cee', d: 'dd' },
      { a: 'aa', b: nil, c: '', d: 'dd' }
    ]
  end
  let(:fields) { %i[b c] }
  let(:fieldset) { Kiba::Extend::Fieldset.new(fields) }
  describe '#fields' do
    it 'returns an Array of fields collated by the Fieldset' do
      expect(fieldset.fields).to eq(fields)
    end
  end
  describe '#populate' do
    it 'populates hash with field values from given rows' do
      fieldset.populate(rows)
      expected = [%w[bb bee], %w[cc cee]]
      expect(fieldset.hash.values).to eq(expected)
    end
  end

  describe '#add_constant_values' do
    it 'populates hash with constant values' do
      fieldset.populate(rows)
      fieldset.add_constant_values(:f, 'ffff')
      expected = [%w[bb bee], %w[cc cee], %w[ffff ffff]]
      expect(fieldset.hash.values).to eq(expected)
    end

    it 'adds field, but does not add constant values to it for empty rows' do
      rows = [
        { a: 'aa' },
        { a: 'aa', b: '' }
      ]
      fieldset.populate(rows)
      fieldset.add_constant_values(:f, 'ffff')
      expected = [[], [], []]
      expect(fieldset.hash.values).to eq(expected)
    end
  end

  describe '#join_values' do
    it 'joins hash values' do
      fieldset.populate(rows)
      fieldset.add_constant_values(:f, 'ffff')
      fieldset.join_values('|')
      expected = ['bb|bee', 'cc|cee', 'ffff|ffff']
      expect(fieldset.hash.values).to eq(expected)
    end
  end
end
