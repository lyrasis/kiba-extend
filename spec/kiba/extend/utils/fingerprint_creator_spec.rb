# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::FingerprintCreator do
  let(:fields) { %i[b c d e] }
  let(:delim) { '|' }
  let(:klass) { described_class.new(fields: fields, delim: delim) }
  
  describe '#call' do
    let(:row) { {a: 'ant', b: 'bee', c: nil, d: 'deer', e: ''} }
    let(:result) { klass.call(row) }
    
    it 'returns expected hashed value' do
      expected = Base64.strict_encode64('bee|nil|deer|empty')
      expect(result).to eq(expected)
    end
  end
end
