# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::Lookup::PairEquality do
  describe 'compares row values to basic string values' do
    context 'when row field value equals string value' do
      it 'returns true' do
        obj = Lookup::PairEquality.new(
          pair: ['row::a', 'value::abc'],
          row: { a: 'abc' }
        )
        expect(obj.result).to be true
      end
    end

    context 'when row field value not equal to string value' do
      it 'returns false' do
        obj = Lookup::PairEquality.new(
          pair: ['row::a', 'value::abc'],
          row: { a: 'a' }
        )
        expect(obj.result).to be false
      end
    end
  end

  describe 'compares row values to regexp values' do
    context 'when row field value equals regexp value' do
      it 'returns true' do
        obj = Lookup::PairEquality.new(
          pair: ['row::a', 'revalue::[Aa].c'],
          row: { a: 'abc' }
        )
        expect(obj.result).to be true
      end
    end

    context 'when row field value not equal to regexp value' do
      it 'returns false' do
        obj = Lookup::PairEquality.new(
          pair: ['row::a', 'revalue::[Aa].c'],
          row: { a: 'abcd' }
        )
        expect(obj.result).to be false
      end
    end

    context 'when regexp value explicitly includes ^ and/or $ anchors' do
      it 'does not re-add them' do
        obj = Lookup::PairEquality.new(
          pair: ['row::a', 'revalue::^[Aa].c$'],
          row: { a: 'abc' }
        )
        expect(obj.result).to be true
      end
    end
  end

  describe 'compares mergerow field values to basic string values' do
    context 'when mergerow field value equals string value' do
      it 'returns true' do
        obj = Lookup::PairEquality.new(
          pair: ['mergerow::a', 'value::abc'],
          row: { b: 'def' },
          mergerow: { a: 'abc' }
        )
        expect(obj.result).to be true
      end
    end

    context 'when mergerow field value not equal to string value' do
      it 'returns false' do
        obj = Lookup::PairEquality.new(
          pair: ['mergerow::a', 'value::abc'],
          row: { b: 'def' },
          mergerow: { a: 'ab' }
        )
        expect(obj.result).to be false
      end
    end

    context 'when mergerow is not passed to class' do
      it 'returns false' do
        obj = Lookup::PairEquality.new(
          pair: ['mergerow::a', 'value::abc'],
          row: { b: 'def' }
        )
        expect(obj.result).to be false
      end
    end
  end

  describe 'compares row field value to mergerow field value' do
    context 'when row and mergerow field values are equal' do
      it 'returns true' do
        obj = Lookup::PairEquality.new(
          pair: ['mergerow::a', 'row::b'],
          row: { b: 'abc' },
          mergerow: { a: 'abc' }
        )
        expect(obj.result).to be true
      end
    end

    context 'when row and mergerow field values are not equal' do
      it 'returns false' do
        obj = Lookup::PairEquality.new(
          pair: ['mergerow::a', 'row::b'],
          row: { b: 'abc' },
          mergerow: { a: 'def' }
        )
        expect(obj.result).to be false
      end
    end

    context 'when neither row nor mergerow contains its specified field' do
      it 'returns true' do
        obj = Lookup::PairEquality.new(
          pair: ['mergerow::a', 'row::b'],
          row: {},
          mergerow: {}
        )
        expect(obj.result).to be true
      end
    end

    context 'when row field exists but is blank and mergerow field does not exist' do
      it 'returns false' do
        obj = Lookup::PairEquality.new(
          pair: ['mergerow::a', 'row::b'],
          row: { b: '' },
          mergerow: {}
        )
        expect(obj.result).to be false
      end
    end
  end
end
