require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Merge do
  let(:test_csv) { 'tmp/test.csv' }
  before do
    generate_csv(test_csv, rows)
  end
  after do
    File.delete(test_csv) if File.exist?(test_csv)
  end
  describe 'ConstantValue' do
    let(:rows) { [
      ['id', 'name', 'sex', 'source'],
      [1, 'Weddy', 'm', 'adopted'],
      [2, 'Kernel', 'f', 'adopted']
    ] }

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
    let(:opt) {
      {
        fieldmap: {reason: 'gift'},
        conditions: {
          include: {
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
    }
    context 'when row meets criteria' do
      let(:rows) { [
        ['id', 'reason', 'note'],
        [1, nil, 'Gift'],
        [2, nil, 'donation']
      ] }

      it 'merges constant data values into specified field' do
        expected = [
          {:id=>'1', :reason=>'gift', :note=>'Gift'},
          {:id=>'2', :reason=>'gift', :note=>'donation'}
        ]
        result = execute_job(filename: test_csv,
                             xform: Merge::ConstantValueConditional,
                             xformopt: opt
                            )
        expect(result).to eq(expected)
      end

      context 'when target field has a pre-existing value' do
        let(:rows) { [
          ['id', 'reason', 'note'],
          [1, 'donation', 'Gift'],
        ] }
        it 'that value is overwritten by the specified constant value' do
          expected = [
            {:id=>'1', :reason=>'gift', :note=>'Gift'}
          ]
          result = execute_job(filename: test_csv,
                               xform: Merge::ConstantValueConditional,
                               xformopt: opt
                              )
          expect(result).to eq(expected)
        end
      end
    end

    context 'when row does not meet criteria' do
      context 'and target field already exists in row' do
        let(:rows) { [
          ['id', 'reason', 'note'],
          [2, 'misc', 'Something else']
        ] }
        it 'target field value stays the same' do
          expected = [
            {:id=>'2', :reason=>'misc', :note=>'Something else'}
          ]
          result = execute_job(filename: test_csv,
                               xform: Merge::ConstantValueConditional,
                               xformopt: opt
                              )
          expect(result).to eq(expected)
        end
      end

      context 'and target field does not exist in row' do
        let(:rows) { [
          ['id', 'note'],
          [2, 'Something else']
        ] }
        it 'target field is added to row, with nil value' do
          expected = [
            {:id=>'2', :reason=>nil, :note=>'Something else'}
          ]
          result = execute_job(filename: test_csv,
                               xform: Merge::ConstantValueConditional,
                               xformopt: opt
                              )
          expect(result).to eq(expected)
        end
      end
    end
  end
  
  describe 'CountOfMatchingRows' do
    let(:rows) { [
      ['id'],
      [0],
      [1],
      [2]
    ] }
    let(:lookup_rows) { [
      ['id'],
      [1],
      [2],
      [2]
    ] }
    let(:lookup) { Lookup.csv_to_multi_hash(file: 'tmp/lkp.csv', csvopt: CSVOPT, keycolumn: :id) }
    let(:xformopt) {{
      lookup: lookup,
      keycolumn: :id,
      targetfield: :ct
    }}
    before do
      generate_csv('tmp/lkp.csv', lookup_rows)
    end
    
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

  describe 'MultivalueConstant' do
    let(:rows) { [
      ['name'],
      ['Weddy'],
      ['NULL'],
      [''],
      [nil],
      ['Earlybird;Divebomber'],
      [';Niblet'],
      ['Hunter;'],
      ['NULL;Earhart']
    ] }

    it 'adds specified value to new field once per value in specified field' do
      expected = [
        { name: 'Weddy', species: 'guinea fowl' },
        { name: 'NULL', species: 'NULL' },
        { name: '', species: 'NULL' },
        { name: nil, species: 'NULL' },
        { name: 'Earlybird;Divebomber', species: 'guinea fowl;guinea fowl' },
        { name: ';Niblet', species: 'NULL;guinea fowl' },
        { name: 'Hunter;', species: 'guinea fowl;NULL' },
        { name: 'NULL;Earhart', species: 'NULL;guinea fowl' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Merge::MultivalueConstant,
                           xformopt: { on_field: :name,
                                      target: :species,
                                      value: 'guinea fowl',
                                      sep: ';',
                                      placeholder: 'NULL'})
      expect(result).to eq(expected)
    end
  end

  describe 'MultiRowLookup' do
    context 'when multikey = false (default)' do
      let(:rows) { [
        ['id', 'name', 'sex', 'source'],
        [1, 'Weddy', 'm', 'adopted'],
        [2, 'Kernel', 'f', 'adopted'],
        [3, 'Boris', 'm', 'adopted'],
        [4, 'Earlybird', 'f', 'hatched'],
        [5, 'Lazarus', 'm', 'adopted'],
        [nil, 'Null', '', '']
      ] }
      lookup_rows = [
        ['id', 'date', 'treatment'],
        [1, '2019-07-21', 'hatch'],
        [2, '2019-08-01', 'hatch'],
        [1, '2019-09-15', 'adopted'],
        [2, '2019-09-15', 'adopted'],
        [1, '2020-04-15', 'deworm'],
        [2, '2020-04-15', 'deworm'],
        [4, '', '']
      ]
      let(:lookup) { Lookup.csv_to_multi_hash(file: 'tmp/lkp.csv', csvopt: CSVOPT, keycolumn: :id) }
      let(:xformopt) { {
        fieldmap: {
          :date => :date,
          :event => :treatment
        },
        lookup: lookup,
        keycolumn: :id
      } }
      before do
        generate_csv('tmp/lkp.csv', lookup_rows)
      end
      
      it 'merges values from specified fields into multivalued fields' do
        expected = [
          {:id=>'1', :name=>'Weddy', :sex=>'m', :source=>'adopted',
           :date=>'2019-07-21;2019-09-15;2020-04-15',
           :event=>'hatch;adopted;deworm'},
          {:id=>'2', :name=>'Kernel', :sex=>'f', :source=>'adopted',
           :date=>'2019-08-01;2019-09-15;2020-04-15',
           :event=>'hatch;adopted;deworm'},
          {:id=>'3', :name=>'Boris', :sex=>'m', :source=>'adopted',
           :date=>nil,
           :event=>nil},
          {:id=>'4', :name=>'Earlybird', :sex=>'f', :source=>'hatched',
           :date=>nil,
           :event=>nil},
          {:id=>'5', :name=>'Lazarus', :sex=>'m', :source=>'adopted',
           :date=>nil,
           :event=>nil} ,
          {:id=>nil, :name=>'Null', :sex=>'', :source=>'',
           :date=>nil,
           :event=>nil}
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
           :loc=>'The Thicket;The Thicket;The Thicket'},
          {:id=>'3', :name=>'Boris', :sex=>'m', :source=>'adopted',
           :date=>nil,
           :event=>nil,
           :by=>nil, :loc=>nil},
          {:id=>'4', :name=>'Earlybird', :sex=>'f', :source=>'hatched',
           :date=>nil,
           :event=>nil,
           :by=>nil, :loc=>nil},
          {:id=>'5', :name=>'Lazarus', :sex=>'m', :source=>'adopted',
           :date=>nil,
           :event=>nil,
           :by=>nil, :loc=>nil},
          {:id=>nil, :name=>'Null', :sex=>'', :source=>'',
           :date=>nil,
           :event=>nil,
           :by=>nil, :loc=>nil}
        ]
        result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: opt)
        expect(result).to eq(expected)
      end

      after do
        File.delete('tmp/lkp.csv') if File.exist?('tmp/lkp.csv')
      end
    end

    context 'when multikey = true' do
      let(:rows) { [
        ['single'],
        ['a|b|c'],
        ['d'],
        ['e|f|g'],
        ['h'],
        [nil]
      ] }
      lookup_rows = [
        ['single', 'double', 'triple'],
        ['a', 'aa', 'aaa'],
        ['b', 'bb', 'bbb'],
        ['b', 'beebee', ''],
        ['c', 'cc', 'ccc'],
        ['d', 'dd', 'ddd'],
        ['e', 'ee', 'eee'],
        ['g', '', 'ggg']
      ]
      let(:lookup) { Lookup.csv_to_multi_hash(file: 'tmp/lkp.csv', csvopt: CSVOPT, keycolumn: :single) }
      let(:xformopt) { {
        fieldmap: {
          doubles: :double,
          triples: :triple
        },
        lookup: lookup,
        keycolumn: :single,
        multikey: true,
        delim: '|'
      } }
      before do
        generate_csv('tmp/lkp.csv', lookup_rows)
      end
      
      it 'merges values from specified fields into multivalued fields' do
        expected = [
          {single: 'a|b|c', doubles: 'aa|bb|beebee|cc', triples: 'aaa|bbb||ccc'},
          {single: 'd', doubles: 'dd', triples: 'ddd'},
          {single: 'e|f|g', doubles: 'ee|', triples: 'eee|ggg'},
          {single: 'h', doubles: nil, triples: nil},
          {single: nil, doubles: nil, triples: nil}
        ]
        result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: xformopt)
        expect(result).to eq(expected)
      end

      it 'merges specified constant values into specified fields for each row merged' do
        opt = xformopt.merge({constantmap: {:quad => 4, :pent => 5}})
        expected = [
          {single: 'a|b|c', doubles: 'aa|bb|beebee|cc', triples: 'aaa|bbb||ccc', quad: '4|4|4|4', pent: '5|5|5|5'},
          {single: 'd', doubles: 'dd', triples: 'ddd', quad: '4', pent: '5'},
          {single: 'e|f|g', doubles: 'ee|', triples: 'eee|ggg', quad: '4|4', pent: '5|5'},
          {single: 'h', doubles: nil, triples: nil, quad: nil, pent: nil},
          {single: nil, doubles: nil, triples: nil, quad: nil, pent: nil}
        ]
        result = execute_job(filename: test_csv, xform: Merge::MultiRowLookup, xformopt: opt)
        expect(result).to eq(expected)
      end

      after do
        File.delete('tmp/lkp.csv') if File.exist?('tmp/lkp.csv')
      end
    end
  end
end
