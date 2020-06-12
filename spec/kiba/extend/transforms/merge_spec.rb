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

  describe 'ConstantValueConditional' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'reason', 'note'],
      [1, nil, 'Gift'],
      [2, nil, 'Something else']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'merges constant data values into field if row meets criteria' do
      expected = [
        {:id=>'1', :reason=>'gift', :note=>'Gift'},
        {:id=>'2', :reason=>nil, :note=>'Something else'}
      ]
      opt = {
        fieldmap: {reason: 'gift'},
        conditions: {
          include: {
            field_empty: { fieldsets: [
              {
                fields: ['row::reason']
              }
            ]},
            field_equal: { fieldsets: [
              {
                matches: [
                  ['row::note', 'revalue::[Gg]ift'],
                  ['row::note', 'revalue::[Dd]onation']
                ]
              }
            ]}
          }
        }
      }
      result = execute_job(filename: test_csv,
                           xform: Merge::ConstantValueConditional,
                           xformopt: opt
                          )
      expect(result).to eq(expected)
    end
  end
  
  describe 'CountOfMatchingRows' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id'],
      [0],
      [1],
      [2]
    ]
    lookup_rows = [
      ['id'],
      [1],
      [2],
      [2]
    ]

    before do
      generate_csv(test_csv, rows)
      generate_csv('tmp/lkp.csv', lookup_rows)
    end
    let(:lookup) { Lookup.csv_to_multi_hash(file: 'tmp/lkp.csv', csvopt: CSVOPT, keycolumn: :id) }
    let(:xformopt) {{
      lookup: lookup,
      keycolumn: :id,
      targetfield: :ct
    }}
    
    it 'merges count of lookup rows to be merged into specified field' do
      expected = [
        {:id=>'0', :ct=>0},
        {:id=>'1', :ct=>1},
        {:id=>'2', :ct=>2}
      ]
      result = execute_job(filename: test_csv, xform: Merge::CountOfMatchingRows, xformopt: xformopt)
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





    ## This complexity isn't necessary, but writing it was a pain so I'll keep it for a while until I'm sure.
    # context 'when multiple exclusion criteria given' do
    #   rows3 = [
    #     ['id', 'name', 'varname'],
    #     [1, 'Weddy', 'WednesdayEddy'],
    #     [2, 'Kernel', 'Little Sweetcorn Kernel;Sweetcorn Kernel']
    #   ]
    #   lookup_rows3 = [
    #     ['id', 'varname2'],
    #     [1, 'Weddy'],
    #     [1, 'WednesdayEddy'],
    #     [1, 'WednesdayEddie'],
    #     [2, 'Kernel'],
    #     [2, 'Little Sweetcorn Kernel'],
    #     [2, 'Sweetcorn Kernel'],
    #     [2, 'Sweetcorn'],
    #     [2, 'Sweet Corn']
    #   ]
    #   before do
    #     generate_csv(test_csv, rows3)
    #     generate_csv('tmp/lkp.csv', lookup_rows3)
    #   end
    #   let(:lookup) { Lookup.csv_to_multi_hash(file: 'tmp/lkp.csv', csvopt: CSVOPT, keycolumn: :id) }
    #   let(:xformopt) {{
    #     lookup: lookup,
    #     keycolumn: :id,
    #     fieldmap: {
    #       :add_varname => :varname2
    #     },
    #     exclusion_criteria: {
    #       :field_equal => {
    #         :name => :varname2
    #       },
    #       :field_include => {
    #         :varname => :varname2
    #       }
    #     }
    #   }}

    #   xit 'merges data from rows matching neither exclusion criteria (field equals)' do
    #     expected = [
    #       {:id=>'1',
    #        :name=>'Weddy',
    #        :varname=>'WednesdayEddy',
    #        :add_varname=>'WednesdayEddie'
    #       },
    #       {:id=>'2',
    #        :name=>'Kernel',
    #        :varname=>'Little Sweetcorn Kernel;Sweetcorn Kernel',
    #        :add_varname=>'Sweetcorn; Sweet Corn'
    #       }
    #     ]
    #     result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: xformopt)
    #     expect(result).to eq(expected)
    #   end
    # end

    after do
      File.delete(test_csv) if File.exist?(test_csv)
      File.delete('tmp/lkp.csv') if File.exist?('tmp/lkp.csv')
    end
  end
end
