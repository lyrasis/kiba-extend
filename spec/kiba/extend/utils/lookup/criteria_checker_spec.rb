# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::Lookup::CriteriaChecker do
  context 'when set match type not specified' do
    it 'defaults to set_type = :all' do
      set = { fieldsets: [
        {
          matches: [
            ['row::a', 'value:abc']
          ]
        }
      ] }
      obj = Lookup::CriteriaChecker.new(
        check_type: :equality,
        config: set,
        row: { a: 'def' }
      )
      expect(obj.type).to eq(:all)
    end
  end

  context 'when type = :all' do
    context 'and all fieldset groups return true' do
      it 'returns true' do
        set = { type: :all,
               fieldsets: [
                 {
                   matches: [
                     ['row::a', 'value::abc']
                   ]
                 },
                 {
                   matches: [
                     ['row::b', 'value::def']
                   ]
                 }
               ] }
        obj = Lookup::CriteriaChecker.new(
          check_type: :equality,
          config: set,
          row: { a: 'abc', b: 'def' }
        )
        expect(obj.result).to be true
      end
    end
  end
end
