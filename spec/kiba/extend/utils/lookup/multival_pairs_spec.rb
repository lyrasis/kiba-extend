# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::Lookup::MultivalPairs do
  it 'explodes pairs into all multivalued comparisons' do
    obj = Lookup::MultivalPairs.new(
      pair: ['mvrow::a', 'mvrow::b'],
      row: { a: 'abc;def;xyz', b: 'def;nop' },
      sep: ';'
    )
    expected = [
      %w[value::abc value::def],
      %w[value::abc value::nop],
      %w[value::def value::def],
      %w[value::def value::nop],
      %w[value::xyz value::def],
      %w[value::xyz value::nop]
    ].sort
    expect(obj.result.sort).to eq(expected)
  end
end
