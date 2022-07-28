# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Clean::EvenFieldValues do
  subject(:xform){ described_class.new(**params) }
  let(:delim){ '|' }
  let(:result){ input.map{ |row| xform.process(row) } }
    let(:input) do
      [
        {foo: 'a', bar: 'b', baz: 'c'},
        {foo: '', bar: nil, baz: 'c'},
        {foo: 'a|a|a', bar: '|b', baz: 'c'}
      ]
    end

  context 'with defaults' do
    let(:params) do
      {
        fields: %i[foo bar baz],
        delim: delim
      }
    end
    
    let(:expected) do
      [
        {foo: 'a', bar: 'b', baz: 'c'},
        {foo: '', bar: nil, baz: 'c'},
        {foo: 'a|a|a', bar: '|b|%NULLVALUE%', baz: 'c|%NULLVALUE%|%NULLVALUE%'}
      ]
    end

    it 'evens columns as specified' do
      expect(result).to eq(expected)
    end
  end

  context 'with `evener: %BLANK%`' do
    let(:params) do
      {
        fields: %i[foo bar baz],
        delim: delim,
        evener: '%BLANK%'
      }
    end
    
    let(:expected) do
      [
        {foo: 'a', bar: 'b', baz: 'c'},
        {foo: '', bar: nil, baz: 'c'},
        {foo: 'a|a|a', bar: '|b|%BLANK%', baz: 'c|%BLANK%|%BLANK%'}
      ]
    end

    it 'evens columns as specified' do
      expect(result).to eq(expected)
    end
  end

  context 'with `evener: :value`' do
    let(:input) do
      [
        {foo: '', bar: nil, baz: 'c'},
        {foo: 'a|a|a', bar: '|b', baz: 'c'},
        {foo: 'a|a|a', bar: 'b|', baz: 'c|a'}
      ]
    end

    let(:params) do
      {
        fields: %i[foo bar baz],
        delim: delim,
        evener: :value
      }
    end
    
    let(:expected) do
      [
        {foo: '', bar: nil, baz: 'c'},
        {foo: 'a|a|a', bar: '|b|b', baz: 'c|c|c'},
        {foo: 'a|a|a', bar: 'b||', baz: 'c|a|a'},
      ]
    end

    it 'evens columns as specified' do
      expect(result).to eq(expected)
    end
  end

end
