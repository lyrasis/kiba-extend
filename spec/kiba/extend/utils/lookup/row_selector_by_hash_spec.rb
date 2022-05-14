# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::Lookup::RowSelectorByHash do
  let(:origrow){ { source: 'adopted' } }
  let(:mergerows) do
    [
      { treatment: 'hatch' },
      { treatment: 'adopted' },
      { treatment: 'hatch' },
      { treatment: 'adopted' },
      { treatment: 'deworm' }
    ]
  end
  let(:klass){ described_class.new(conditions: conditions) }

  describe '#call' do
    let(:result){ klass.call(origrow: origrow, mergerows: mergerows) }
    
    context 'when inclusion criteria' do
      context 'includes :position => "first"' do
        let(:conditions) do
          {
            include: {
              position: 'first'
            }
          }
        end
        
        it 'keeps only the first mergerow' do
          expected = [
            { treatment: 'hatch' }
          ]
          expect(result).to eq(expected)
        end
      end
      
      context 'includes :field_equal comparing to a string value' do
        let(:conditions) do
          {
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
        end

        it 'keeps only mergerows containing field equal to given value' do
          expected = [
            { treatment: 'hatch' },
            { treatment: 'hatch' }
          ]
          expect(result).to eq(expected)
        end
      end

      context 'includes :field_equal comparing to a regexp value' do
        let(:conditions) do
          {
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
        end
        
        it 'keeps only mergerows containing field matching given regexp' do
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
          let(:conditions) do
            {
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
          end
          
          it 'rejects expected mergerows' do
            expected = [
              { treatment: 'hatch' },
              { treatment: 'hatch' },
              { treatment: 'deworm' }
            ]
            expect(result).to eq(expected)
          end
        end

        context 'with multiple pairs of fields' do
          let(:origrow){ { source: 'adopted', color: 'coral blue' } }
          let(:mergerows) do
            [
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
          end
          let(:conditions) do
            {
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
          end
          
          it 'rejects expected mergerows' do
            expected = [
              { treatment: 'hatch', gotfrom: 'self', type: 'pearl' },
              { treatment: 'purchased', gotfrom: 'friend', type: 'buff dundotte' }
            ]
            expect(result).to eq(expected)
          end
        end
      end

      context 'includes :field_empty' do
        let(:origrow){ { source: 'adopted', color: 'coral blue' } }
        let(:mergerows) do
          [
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
        end
        
        context 'when one field specified' do
          let(:conditions) do
            {
              exclude: {
                field_empty: {
                  fieldsets: [
                    { fields: %w[mergerow::treatment] }
                  ]
                }
              }
            }
          end
          
          it 'rejects expected mergerows' do
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
          let(:conditions) do
            {
              exclude: {
                field_empty: {
                  fieldsets: [
                    { type: :any, fields: %w[mergerow::treatment mergerow::gotfrom] }
                  ]
                }
              }
            }
          end
          
          it 'rejects mergerows where ANY of the fields listed are empty' do
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
      let(:origrow){ { source: 'adopted', color: 'coral blue' } }
      let(:mergerows) do
        [
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
      end
      let(:conditions) do
        {
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
      end
      
      it 'rejects excluded before selecting included' do

        expected = [
          { treatment: 'hatch', gotfrom: 'self', type: 'pearl' }
        ]
        expect(result).to eq(expected)
      end
    end
  end
end
