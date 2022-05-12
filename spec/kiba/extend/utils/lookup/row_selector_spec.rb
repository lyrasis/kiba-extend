# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::Lookup::RowSelector do
  context 'when inclusion criteria' do
    context 'includes :position => "first"' do
      it 'keeps only the first mergerow' do
        origrow = { source: 'adopted' }
        mergerows = [
          { treatment: 'hatch' },
          { treatment: 'adopted' },
          { treatment: 'hatch' },
          { treatment: 'adopted' },
          { treatment: 'deworm' }
        ]
        conditions = {
          include: {
            position: 'first'
          }
        }
        result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
        expected = [
          { treatment: 'hatch' }
        ]
        expect(result).to eq(expected)
      end
    end
    context 'includes :field_equal comparing to a string value' do
      it 'keeps only mergerows containing field equal to given value' do
        origrow = { source: 'adopted' }
        mergerows = [
          { treatment: 'hatch' },
          { treatment: 'adopted' },
          { treatment: 'hatch' },
          { treatment: 'adopted' },
          { treatment: 'deworm' }
        ]
        conditions = {
          include: {
            field_equal: { fieldsets: [
              {
                type: :any,
                matches: [
                  ['mergerow::treatment', 'value::hatch']
                ]
              }
            ] }
          }
        }
        result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
        expected = [
          { treatment: 'hatch' },
          { treatment: 'hatch' }
        ]
        expect(result).to eq(expected)
      end
    end
    context 'includes :field_equal comparing to a regexp value' do
      it 'keeps only mergerows containing field matching given regexp' do
        origrow = { source: 'adopted' }
        mergerows = [
          { treatment: 'hatch' },
          { treatment: 'adopted' },
          { treatment: 'hatch' },
          { treatment: 'adopted' },
          { treatment: 'deworm' },
          { treatment: 'hatches' }
        ]
        conditions = {
          include: {
            field_equal: { fieldsets: [
              {
                type: :any,
                matches: [
                  ['mergerow::treatment', 'revalue::[Hh]atch']
                ]
              }
            ] }
          }
        }
        result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
        expected = [
          { treatment: 'hatch' },
          { treatment: 'hatch' }
        ]
        expect(result).to eq(expected)
      end
    end
  end
  context 'when exclusion criteria' do
    context 'includes :src_field_equal_merge_field' do
      context 'with single pair of fields' do
        it 'rejects expected mergerows' do
          origrow = { source: 'adopted' }
          mergerows = [
            { treatment: 'hatch' },
            { treatment: 'adopted' },
            { treatment: 'hatch' },
            { treatment: 'adopted' },
            { treatment: 'deworm' }
          ]
          conditions = {
            exclude: {
              field_equal: { fieldsets: [
                {
                  type: :any,
                  matches: [
                    ['row::source', 'mergerow::treatment']
                  ]
                }
              ] }
            }
          }
          result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
          expected = [
            { treatment: 'hatch' },
            { treatment: 'hatch' },
            { treatment: 'deworm' }
          ]
          expect(result).to eq(expected)
        end
      end

      context 'with multiple pairs of fields' do
        it 'rejects expected mergerows' do
          origrow = { source: 'adopted', color: 'coral blue' }
          mergerows = [
            { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' },
            { treatment: 'hatch', gotfrom: 'adopted', type: 'coral blue' },
            { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
            { treatment: 'hatch', gotfrom: 'self', type: 'coral blue' },
            { treatment: 'adopted', gotfrom: 'friend', type: 'coral blue' },
            { treatment: 'adopted', gotfrom: 'friend', type: 'buff dundotte' },
            { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' },
            { treatment: 'purchased', gotfrom: 'adopted', type: 'royal purple' },
            { treatment: 'purchased', gotfrom: 'friend', type: 'coral blue' }
          ]
          conditions = {
            exclude: {
              field_equal: { fieldsets: [
                {
                  type: :any,
                  matches: [
                    ['row::source', 'mergerow::treatment'],
                    ['row::source', 'mergerow::gotfrom'],
                    ['row::color', 'mergerow::type']
                  ]
                }
              ] }
            }
          }
          result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
          expected = [
            { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
            { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' }
          ]
          expect(result).to eq(expected)
        end
      end
    end

    context 'includes :field_empty' do
      origrow = { source: 'adopted', color: 'coral blue' }
      mergerows = [
        { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' },
        { treatment: nil, gotfrom: '', type: 'coral blue' },
        { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
        { treatment: '', gotfrom: nil, type: 'coral blue' },
        { treatment: 'adopted', gotfrom: nil, type: 'coral blue' },
        { treatment: nil, gotfrom: nil, type: 'buff dundotte' },
        { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' },
        { treatment: '', gotfrom: '', type: 'royal purple' },
        { treatment: 'purchased', gotfrom: '', type: 'coral blue' }
      ]
      context 'when one field specified' do
        it 'rejects expected mergerows' do
          conditions = {
            exclude: {
              field_empty: {
                fieldsets: [
                  { fields: %w[mergerow::treatment] }
                ]
              }
            }
          }
          result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
          expected = [
            { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' },
            { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
            { treatment: 'adopted', gotfrom: nil, type: 'coral blue' },
            { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' },
            { treatment: 'purchased', gotfrom: '', type: 'coral blue' }
          ]
          expect(result).to eq(expected)
        end
      end
      context 'when multiple fields specified' do
        it 'rejects mergerows where ANY of the fields listed are empty' do
          conditions = {
            exclude: {
              field_empty: {
                fieldsets: [
                  { type: :any, fields: %w[mergerow::treatment mergerow::gotfrom] }
                ]
              }
            }
          }
          result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, conditions: conditions).result
          expected = [
            { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' },
            { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
            { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' }
          ]
          expect(result).to eq(expected)
        end
      end
    end
  end

  context 'when inclusion and exclusion criteria' do
    it 'rejects excluded before selecting included' do
      origrow = { source: 'adopted', color: 'coral blue' }
      mergerows = [
        { treatment: nil, gotfrom: '', type: 'coral blue' },
        { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
        { treatment: '', gotfrom: nil, type: 'coral blue' },
        { treatment: 'adopted', gotfrom: nil, type: 'coral blue' },
        { treatment: nil, gotfrom: nil, type: 'buff dundotte' },
        { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' },
        { treatment: '', gotfrom: '', type: 'royal purple' },
        { treatment: 'purchased', gotfrom: '', type: 'coral blue' },
        { treatment: 'hatch', gotfrom: 'adopted', type: 'pearl' }
      ]
      conditions = {
        exclude: {
          field_empty: {
            fieldsets: [
              { type: :all, fields: %w[mergerow::treatment mergerow::gotfrom] }
            ]
          }
        },
        include:
        {
          position: 'first'
        }
      }

      result = Lookup::RowSelector.new(origrow: origrow,
                                       mergerows: mergerows,
                                       conditions: conditions).result
      expected = [
        { treatment: 'hatch', gotfrom: 'self', type: 'pearl' }
      ]
      expect(result).to eq(expected)
    end
  end
end
