require 'spec_helper'

RSpec.describe Kiba::Extend::Utils::Lookup do
  test_csv = 'tmp/test.csv'
  rows = [
    ['id', 'val'],
    ['1', 'a'],
    ['2', 'b'],
    ['3', 'c'],
    ['3', 'd']
  ]
  before { generate_csv(test_csv, rows) }
  after { File.delete(test_csv) if File.exist?(test_csv) }
  
  describe '#csv_to_hash' do
    lookup_hash = {
      '1' => {:id=>'1', :val=>'a'},
      '2' => {:id=>'2', :val=>'b'},
      '3' => {:id=>'3', :val=>'d'}
    }

    
    it 'returns hash with key = keycolumn value and value = last occurring row w/that key ' do
      result = Lookup.csv_to_hash(file: test_csv,
                                       csvopt: CSVOPT,
                                       keycolumn: :id)
      expect(result).to eq(lookup_hash)
    end
  end

  describe '#csv_to_multi_hash' do
    lookup_hash = {
      '1' => [{:id=>'1', :val=>'a'}],
      '2' => [{:id=>'2', :val=>'b'}],
      '3' => [{:id=>'3', :val=>'c'},
              {:id=>'3', :val=>'d'}]
    }

    
    it 'returns hash with key = keycolumn value and value = array of all rows w/that key ' do
      result = Lookup.csv_to_multi_hash(file: test_csv,
                                       csvopt: CSVOPT,
                                       keycolumn: :id)
      expect(result).to eq(lookup_hash)
    end
  end

  describe Lookup::RowSelector do
    context 'when inclusion criteria' do
      context 'includes :position => "first"' do
         it 'keeps only the first mergerow' do
            origrow = {:source => 'adopted'}
            mergerows = [
              {:treatment => 'hatch'},
              {:treatment => 'adopted'},
              {:treatment => 'hatch'},
              {:treatment => 'adopted'},
              {:treatment => 'deworm'}
            ]
            include = {
              :position => 'first'
            }
            result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, include: include).result
            expected = [
              {:treatment => 'hatch'}
            ]
            expect(result).to eq(expected)
         end
      end
      context 'includes :field_equal comparing to a string value' do
        it 'keeps only mergerows containing field equal to given value' do
          origrow = {:source => 'adopted'}
          mergerows = [
            {:treatment => 'hatch'},
            {:treatment => 'adopted'},
            {:treatment => 'hatch'},
            {:treatment => 'adopted'},
            {:treatment => 'deworm'}
          ]
          include = {
            :field_equal => [
              ['mergerow::treatment', 'value::hatch']
            ]
          }
          result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, include: include).result
          expected = [
            {:treatment => 'hatch'},
            {:treatment => 'hatch'}
          ]
          expect(result).to eq(expected)
        end
      end
      context 'includes :field_equal comparing to a regexp value' do
        it 'keeps only mergerows containing field matching given regexp' do
          origrow = {:source => 'adopted'}
          mergerows = [
            {:treatment => 'hatch'},
            {:treatment => 'adopted'},
            {:treatment => 'hatch'},
            {:treatment => 'adopted'},
            {:treatment => 'deworm'}
          ]
          include = {
            :field_equal => [
              ['mergerow::treatment', 'revalue::h$']
            ]
          }
          result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, include: include).result
          expected = [
            {:treatment => 'hatch'},
            {:treatment => 'hatch'}
          ]
          expect(result).to eq(expected)
        end
      end
    end
    context 'when exclusion criteria' do
      context 'includes :src_field_equal_merge_field' do
        context 'with single pair of fields' do
          it 'rejects expected mergerows' do
            origrow = {:source => 'adopted'}
            mergerows = [
              {:treatment => 'hatch'},
              {:treatment => 'adopted'},
              {:treatment => 'hatch'},
              {:treatment => 'adopted'},
              {:treatment => 'deworm'}
            ]
            exclude = {
              :field_equal => [
                ['row::source', 'mergerow::treatment']
                ]
            }
            result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, exclude: exclude).result
            expected = [
              {:treatment => 'hatch'},
              {:treatment => 'hatch'},
              {:treatment => 'deworm'}
            ]
            expect(result).to eq(expected)
          end
        end
        
        context 'with multiple pairs of fields' do
          it 'rejects expected mergerows' do
            origrow = {:source => 'adopted', :color => 'coral blue'}
            mergerows = [
              {:treatment => 'hatch', :gotfrom => 'adopted', :type => 'pearl'},
              {:treatment => 'hatch', :gotfrom => 'adopted', :type => 'coral blue'},
              {:treatment => 'hatch', :gotfrom => 'self', :type => 'pearl'},
              {:treatment => 'hatch', :gotfrom => 'self', :type => 'coral blue'},
              {:treatment => 'adopted', :gotfrom => 'friend', :type => 'coral blue'},
              {:treatment => 'adopted', :gotfrom => 'friend', :type => 'buff dundotte'},
              {:treatment => 'purchased', :gotfrom => 'friend', :type => 'buff dundotte'},
              {:treatment => 'purchased', :gotfrom => 'adopted', :type => 'royal purple'},
              {:treatment => 'purchased', :gotfrom => 'friend', :type => 'coral blue'},
            ]
            exclude = {
              :field_equal => [
                ['row::source', 'mergerow::treatment'],
                ['row::source', 'mergerow::gotfrom'],
                ['row::color', 'mergerow::type']
              ]
            }
            result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, exclude: exclude).result
            expected = [
              {:treatment => 'hatch', :gotfrom => 'self', :type => 'pearl'},
              {:treatment => 'purchased', :gotfrom => 'friend', :type => 'buff dundotte'},
            ]
            expect(result).to eq(expected)
          end
        end
      end

      context 'includes :field_empty' do
        origrow = {:source => 'adopted', :color => 'coral blue'}
        mergerows = [
          {:treatment => 'hatch', :gotfrom => 'adopted', :type => 'pearl'},
          {:treatment => nil, :gotfrom => '', :type => 'coral blue'},
          {:treatment => 'hatch', :gotfrom => 'self', :type => 'pearl'},
          {:treatment => '', :gotfrom => nil, :type => 'coral blue'},
          {:treatment => 'adopted', :gotfrom => nil, :type => 'coral blue'},
          {:treatment => nil, :gotfrom => nil, :type => 'buff dundotte'},
          {:treatment => 'purchased', :gotfrom => 'friend', :type => 'buff dundotte'},
          {:treatment => '', :gotfrom => '', :type => 'royal purple'},
          {:treatment => 'purchased', :gotfrom => '', :type => 'coral blue'},
        ]
        context 'when one field specified' do
          it 'rejects expected mergerows' do
            exclude = {
              :field_empty => [
                :treatment
              ]
            }
            result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, exclude: exclude).result
            expected = [
              {:treatment => 'hatch', :gotfrom => 'adopted', :type => 'pearl'},
              {:treatment => 'hatch', :gotfrom => 'self', :type => 'pearl'},
              {:treatment => 'adopted', :gotfrom => nil, :type => 'coral blue'},
              {:treatment => 'purchased', :gotfrom => 'friend', :type => 'buff dundotte'},
              {:treatment => 'purchased', :gotfrom => '', :type => 'coral blue'},
            ]
            expect(result).to eq(expected)
          end
        end
        context 'when multiple fields specified' do
          it 'rejects mergerows where ANY of the fields listed are empty' do
            exclude = {
              :field_empty => [
                :treatment,
                :gotfrom
              ]
            }
            result = Lookup::RowSelector.new(origrow: origrow, mergerows: mergerows, exclude: exclude).result
            expected = [
              {:treatment => 'hatch', :gotfrom => 'adopted', :type => 'pearl'},
              {:treatment => 'hatch', :gotfrom => 'self', :type => 'pearl'},
              {:treatment => 'purchased', :gotfrom => 'friend', :type => 'buff dundotte'},
            ]
            expect(result).to eq(expected)
          end
        end
      end
    end
    
    context 'when inclusion and exclusion criteria' do
      it 'rejects excluded before selecting included' do
        origrow = {:source => 'adopted', :color => 'coral blue'}
        mergerows = [
          {:treatment => nil, :gotfrom => '', :type => 'coral blue'},
          {:treatment => 'hatch', :gotfrom => 'self', :type => 'pearl'},
          {:treatment => '', :gotfrom => nil, :type => 'coral blue'},
          {:treatment => 'adopted', :gotfrom => nil, :type => 'coral blue'},
          {:treatment => nil, :gotfrom => nil, :type => 'buff dundotte'},
          {:treatment => 'purchased', :gotfrom => 'friend', :type => 'buff dundotte'},
          {:treatment => '', :gotfrom => '', :type => 'royal purple'},
          {:treatment => 'purchased', :gotfrom => '', :type => 'coral blue'},
          {:treatment => 'hatch', :gotfrom => 'adopted', :type => 'pearl'},
        ]
        exclude = {
          :field_empty => [
            :treatment,
            :gotfrom
          ]
        }
        include = {
          :position => 'first'
        }
        result = Lookup::RowSelector.new(origrow: origrow,
                                         mergerows: mergerows,
                                         exclude: exclude,
                                         include: include).result
        expected = [
          {:treatment => 'hatch', :gotfrom => 'self', :type => 'pearl'}
        ]
        expect(result).to eq(expected)
      end
    end #context 'when inclusion and exclusion criteria' do
    
  end #describe RowSelector
end
