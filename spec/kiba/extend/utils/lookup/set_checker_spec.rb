# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::Lookup::SetChecker do
  context 'when set match type not specified' do
    it 'defaults to set_type = :any' do
      set = {
        matches: [
          ['row::a', 'value:abc'],
          ['row::a', 'value:def']
        ]
      }
      obj = Lookup::SetChecker.new(
        check_type: :equality,
        set: set,
        row: { a: 'def' }
      )
      expect(obj.set_type).to eq(:any)
    end
  end

  context 'when set match type = :any' do
    context 'and one or more of the matches = true' do
      it 'returns true' do
        set = {
          type: :any,
          matches: [
            ['row::a', 'value::abc'],
            ['row::a', 'value::def']
          ]
        }
        obj = Lookup::SetChecker.new(
          check_type: :equality,
          set: set,
          row: { a: 'def' }
        )
        expect(obj.result).to be true
      end
    end

    context 'and none of the matches = true' do
      it 'returns false' do
        set = {
          type: :any,
          matches: [
            ['row::a', 'value::abc'],
            ['row::a', 'value::def']
          ]
        }
        obj = Lookup::SetChecker.new(
          check_type: :equality,
          set: set,
          row: { a: 'ghi' }
        )
        expect(obj.result).to be false
      end
    end
  end

  context 'when set match type = :all' do
    context 'and one or more of the matches = true' do
      it 'returns true' do
        set = {
          type: :all,
          matches: [
            ['row::a', 'value::def'],
            ['row::b', 'mvmergerow::a']
          ]
        }
        obj = Lookup::SetChecker.new(
          check_type: :equality,
          set: set,
          row: { a: 'def', b: 'abc' },
          mergerow: { a: 'abc;xyz' },
          sep: ';'
        )
        expect(obj.result).to be true
      end
    end

    context 'and one or more matches = false' do
      it 'returns false' do
        set = {
          type: :all,
          matches: [
            ['row::a', 'value::abc'],
            ['row::b', 'mergerow::a']
          ]
        }
        obj = Lookup::SetChecker.new(
          check_type: :equality,
          set: set,
          row: { a: 'ghi', b: 'def' },
          mergerow: { a: 'abc' }
        )
        expect(obj.result).to be false
      end
    end
  end
end
