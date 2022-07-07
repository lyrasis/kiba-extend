# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Cspace::FieldGroupCombiner do
  subject(:xform){ described_class.new(**params) }
  let(:params){ {sources: sources, targets: targets, delim: delim} }
  let(:sources){ %i[a b] }
  let(:targets){ %i[foo bar] }
  let(:delim){ '|' }
  let(:result){ input.map{ |row| xform.process(row) } }

  let(:input) do
    [
      {a_foo: 'afoo', a_bar: 'abar', b_foo: 'bfoo', b_bar: 'bbar'},
      {a_foo: 'afoo', a_bar: 'abar', b_foo: nil, b_bar: ''},
      {a_foo: 'afoo', a_bar: 'abar', b_foo: nil, b_bar: '%NULLVALUE%'},
      {a_foo: 'afoo', a_bar: '%NULLVALUE%', b_foo: '%NULLVALUE%', b_bar: 'bbar'},
      {a_foo: nil, a_bar: nil, b_foo: nil, b_bar: ''},
      {a_foo: 'afoo', a_bar: 'abar', b_foo: 'bfoo'},
    ]
  end

  context 'with empty_groups: :delete' do
    let(:expected) do
      [
        {foo: 'afoo|bfoo', bar: 'abar|bbar'},
        {foo: 'afoo', bar: 'abar'},
        {foo: 'afoo', bar: 'abar'},
        {foo: 'afoo|%NULLVALUE%', bar: '%NULLVALUE%|bbar'},
        {foo: nil, bar: nil},
        {foo: 'afoo|bfoo', bar: 'abar|%NULLVALUE%'}
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end

  context 'with empty_groups: :retain' do
    let(:params){ {sources: sources, targets: targets, delim: delim, empty_groups: :retain} }
    let(:expected) do
      [
        {foo: 'afoo|bfoo', bar: 'abar|bbar'},
        {foo: 'afoo|', bar: 'abar|'},
        {foo: 'afoo|', bar: 'abar|%NULLVALUE%'},
        {foo: 'afoo|%NULLVALUE%', bar: '%NULLVALUE%|bbar'},
        {foo: nil, bar: nil},
        {foo: 'afoo|bfoo', bar: 'abar|'}
      ]
    end
    
    it 'transforms as expected' do
      expect(result).to eq(expected)
    end
  end
end
