require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge do
  describe 'ConstantValue' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'name', 'sex', 'source'],
      [1, 'Weddy', 'm', 'adopted'],
      [2, 'Kernel', 'f', 'adopted']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'merges specified constant data values into row' do
      expected = [
        {:id=>'1', :name=>'Weddy', :sex=>'m', :source=>'adopted', :species=>'guinea fowl'},
        {:id=>'2', :name=>'Kernel', :sex=>'f', :source=>'adopted', :species=>'guinea fowl'},
      ]
      result = execute_job(filename: test_csv,
                           xform: Merge::ConstantValue,
                           xformopt: {target: :species, value: 'guinea fowl'})
      expect(result).to eq(expected)
    end
  end

  describe 'MultiRowLookup' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'name', 'sex', 'source'],
      [1, 'Weddy', 'm', 'adopted'],
      [2, 'Kernel', 'f', 'adopted']
    ]
    lookup_rows = [
      ['id', 'date', 'treatment'],
      [1, '2019-07-21', 'hatch'],
      [2, '2019-08-01', 'hatch'],
      [1, '2019-09-15', 'adopted'],
      [2, '2019-09-15', 'adopted'],
      [1, '2020-04-15', 'deworm'],
      [2, '2020-04-15', 'deworm'],
    ]
    lookup_rows2 = [
      ['id', 'date', 'treatment'],
      [1, '2019-09-15', 'adopted'],
      [2, '2019-09-15', 'adopted'],
      [1, '2019-07-21', 'hatch'],
      [2, '2019-08-01', 'hatch'],
      [1, '2020-04-15', 'deworm'],
      [2, '2020-04-15', 'deworm'],
    ]
    
    before do
      generate_csv(test_csv, rows)
      generate_csv('tmp/lkp.csv', lookup_rows)
    end
    let(:lookup) { Lookup.csv_to_multi_hash(file: 'tmp/lkp.csv', csvopt: CSVOPT, keycolumn: :id) }
    let(:xformopt) {{
      fieldmap: {
        :date => :date,
        :event => :treatment
      },
      lookup: lookup,
      keycolumn: :id
    }}
    
    it 'merges values from specified fields into multivalued fields' do
      expected = [
        {:id=>'1', :name=>'Weddy', :sex=>'m', :source=>'adopted',
         :date=>'2019-07-21;2019-09-15;2020-04-15',
         :event=>'hatch;adopted;deworm'},
        {:id=>'2', :name=>'Kernel', :sex=>'f', :source=>'adopted',
         :date=>'2019-08-01;2019-09-15;2020-04-15',
         :event=>'hatch;adopted;deworm'}
      ]
      result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: xformopt)
      expect(result).to eq(expected)
    end

    it 'merges specified constant values into specified fields for each row merged' do
      opt = xformopt.merge({constantmap: {:by => 'kms', :loc => 'The Thicket'}})
      expected = [
        {:id=>'1', :name=>'Weddy', :sex=>'m', :source=>'adopted',
         :date=>'2019-07-21;2019-09-15;2020-04-15',
         :event=>'hatch;adopted;deworm',
         :by=>'kms;kms;kms',
         :loc=>'The Thicket;The Thicket;The Thicket'},
        {:id=>'2', :name=>'Kernel', :sex=>'f', :source=>'adopted',
         :date=>'2019-08-01;2019-09-15;2020-04-15',
         :event=>'hatch;adopted;deworm',
         :by=>'kms;kms;kms',
         :loc=>'The Thicket;The Thicket;The Thicket'}
      ]
      result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: opt)
      expect(result).to eq(expected)
    end

    it 'does not merge data from rows matching exclusion criteria (field equals)' do
      opt = xformopt.merge({constantmap: {:by => 'kms', :loc => 'The Thicket'},
                            exclusion_criteria: {
                              :field_equal => {:source => :treatment}
                            }
                           })
      expected = [
        {:id=>'1', :name=>'Weddy', :sex=>'m', :source=>'adopted',
         :date=>'2019-07-21;2020-04-15',
         :event=>'hatch;deworm',
         :by=>'kms;kms',
         :loc=>'The Thicket;The Thicket'},
        {:id=>'2', :name=>'Kernel', :sex=>'f', :source=>'adopted',
         :date=>'2019-08-01;2020-04-15',
         :event=>'hatch;deworm',
         :by=>'kms;kms',
         :loc=>'The Thicket;The Thicket'}
      ]
      result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: opt)
      expect(result).to eq(expected)
    end

    context 'when inclusion and exclusion criteria given' do
      before do
        generate_csv(test_csv, rows)
        generate_csv('tmp/lkp.csv', lookup_rows2)
      end


      it 'merges data from rows matching selection (first) and exclusion criteria (field equals)' do
        opt = xformopt.merge({constantmap: {:by => 'kms', :loc => 'The Thicket'},
                              exclusion_criteria: {
                                :field_equal => {:source => :treatment}
                              },
                              selection_criteria: {:position => 'first'}
                             })
        expected = [
          {:id=>'1', :name=>'Weddy', :sex=>'m', :source=>'adopted',
           :date=>'2019-07-21',
           :event=>'hatch',
           :by=>'kms',
           :loc=>'The Thicket'},
          {:id=>'2', :name=>'Kernel', :sex=>'f', :source=>'adopted',
           :date=>'2019-08-01',
           :event=>'hatch',
           :by=>'kms',
           :loc=>'The Thicket'}
        ]
        result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: opt)
        expect(result).to eq(expected)
      end
    end

    after do
      File.delete(test_csv) if File.exist?(test_csv)
      File.delete('tmp/lkp.csv') if File.exist?('tmp/lkp.csv')
    end
  end
end
