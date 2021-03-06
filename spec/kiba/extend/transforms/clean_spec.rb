require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Clean do
  describe 'AlphabetizeFieldValues' do
    test_csv = 'tmp/test.csv'
    rows = [
        ['id', 'type'],
        ['1', 'Person;unmapped;Organization'],
        ['2', ';'],
        ['3', nil],
        ['4', ''],
        ['5', 'Person;notmapped']
      ]
    
      before { generate_csv(test_csv, rows) }
      let(:result) { execute_job(filename: test_csv,
                                 xform: Clean::AlphabetizeFieldValues,
                                 xformopt: {fields: %i[type], delim: ';'}) }
      it 'sorts field values alphabetically' do
        expect(result[0][:type]).to eq('Organization;Person;unmapped')
        expect(result[4][:type]).to eq('notmapped;Person')
      end
      it 'leaves delimiter-only fields alone' do
        expect(result[1][:type]).to eq(';')
      end
      it 'leaves nil fields alone' do
        expect(result[2][:type]).to be_nil
      end
      it 'leaves empty string fields alone' do
        expect(result[3][:type]).to eq('')
      end
  end

  describe 'ClearFields' do
    test_csv = 'tmp/test.csv'
    rows = [
        ['id', 'type'],
        ['1', 'Person;unmapped;Organization'],
        ['2', ';'],
        ['3', nil],
        ['4', ''],
        ['5', 'Person;notmapped']
      ]
    
    before { generate_csv(test_csv, rows) }
    context 'without additional arguments' do
      it 'sets the value of the field in all rows to nil' do
        result = execute_job(filename: test_csv,
                                   xform: Clean::ClearFields,
                                   xformopt: {fields: %i[type]})
        expect(result.map{ |e| e[1]}.uniq[0]).to be_nil
      end
    end
    context 'with if_equals argument' do
      it 'sets the value of the field to nil if it matches `if_equals`' do
        result = execute_job(filename: test_csv,
                             xform: Clean::ClearFields,
                             xformopt: {fields: %i[type], if_equals: ';'})
        expected = [
          {:id=>'1', :type=>'Person;unmapped;Organization'},
          {:id=>'2', :type=>nil},
          {:id=>'3', :type=>nil},
          {:id=>'4', :type=>''},
          {:id=>'5', :type=>'Person;notmapped'},
        ]
        expect(result.map{ |e| e[1]}.uniq[0]).to be_nil
      end
    end
  end

  describe 'DelimiterOnlyFields' do
    let(:test_csv) { 'tmp/test.csv' }
    let(:rows) { [
      ['id', 'in_set'],
      ['1', 'a; b'],
      ['2', ';'],
      ['3', nil],
      ['4', '%NULLVALUE%;%NULLVALUE%;%NULLVALUE%']
    ] }
    let(:result) { execute_job(filename: test_csv, xform: Clean::DelimiterOnlyFields, xformopt: options) }

    before { generate_csv(test_csv, rows) }
    after { File.delete(test_csv) if File.exist?(test_csv) }
    
    context 'when use_nullvalue = false (the default)' do
      let(:options) { {delim: ';'} }
      it 'changes delimiter only fields to nil' do
        expect(result[1][:in_set]).to be_nil
      end
      it 'leaves other fields unchanged' do
        expect(result[0][:in_set]).to eq('a; b')
        expect(result[2][:in_set]).to be_nil
        expect(result[3][:in_set]).to eq('%NULLVALUE%;%NULLVALUE%;%NULLVALUE%')
      end
    end

    context 'when use_nullvalue = true' do
      let(:options) { {delim: ';', use_nullvalue: true} }
      it 'changes delimiter only fields to nil' do
        expect(result[1][:in_set]).to be_nil
        expect(result[3][:in_set]).to be_nil
      end
      it 'leaves other fields unchanged' do
        expect(result[0][:in_set]).to eq('a; b')
        expect(result[2][:in_set]).to be_nil
      end
    end
  end

  describe 'DowncaseFieldValues' do
    test_csv = 'tmp/test.csv'
    after { File.delete(test_csv) if File.exist?(test_csv) }

    it 'downcases value(s) of specified field(s)' do
      rows = [
        ['val', 'x'],
        ['Aaa', '123'],
        ['Bbb', '']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::DowncaseFieldValues,
                           xformopt: {
                             fields: [:val, :x]
                           })
      expected = [
        {:val=>'aaa', :x=>'123'},
        {:val=>'bbb', :x=>''}
      ]
      expect(result).to eq(expected)
    end
  end

  describe 'EmptyFieldGroups' do
    let(:test_csv) { 'tmp/test.csv' }
    let(:rows) { [
        ['id', 'a1', 'a2', 'b1', 'b2', 'b3'],
        ['4', 'not;', nil, ';empty', ';empty', ';empty'],
        ['1', 'not;empty', 'not;empty', 'not;empty', 'not;empty', 'not;empty'],
        ['2', 'not;', 'not;', ';empty', 'not;empty', ';empty'],
        ['3', ';', ';', ';empty', ';empty', ';empty'],
        ['5', '%NULLVALUE%;%NULLVALUE%', '%NULLVALUE%;%NULLVALUE%', 'not;empty', '%NULLVALUE%;empty', 'empty;%NULLVALUE%'],
        ['6', ';', ';', '%NULLVALUE%;empty', '%NULLVALUE%;empty', '%NULLVALUE%;empty'],
      ] }
    after { File.delete(test_csv) if File.exist?(test_csv) }

    context 'When use_nullvalue = false (the default)' do
    it 'Removes field groups where all fields in group are empty' do
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::EmptyFieldGroups,
                           xformopt: {
                             groups: [
                               %i[a1 a2],
                               %i[b1 b2 b3]
                             ],
                             sep: ';',
                             use_nullvalue: false
                           })
      expected = [
        {:id=>'4',
         :a1=>'not',
         :a2=>nil,
         :b1=>'empty',
         :b2=>'empty',
         :b3=>'empty'
        },
        {:id=>'1',
         :a1=>'not;empty',
         :a2=>'not;empty',
         :b1=>'not;empty',
         :b2=>'not;empty',
         :b3=>'not;empty'
        },
        {:id=>'2',
         :a1=>'not',
         :a2=>'not',
         :b1=>';empty',
         :b2=>'not;empty',
         :b3=>';empty'
        },
        {:id=>'3',
         :a1=>nil,
         :a2=>nil,
         :b1=>'empty',
         :b2=>'empty',
         :b3=>'empty'
        },
        {:id=>'5',
         :a1=>'%NULLVALUE%;%NULLVALUE%',
         :a2=>'%NULLVALUE%;%NULLVALUE%',
         :b1=>'not;empty',
         :b2=>'%NULLVALUE%;empty',
         :b3=>'empty;%NULLVALUE%'
        },
        {:id=>'6',
         :a1=>nil,
         :a2=>nil,
         :b1=>'%NULLVALUE%;empty',
         :b2=>'%NULLVALUE%;empty',
         :b3=>'%NULLVALUE%;empty'
        }
      ]
      expect(result).to eq(expected)
    end
    end
    context 'When use_nullvalue = true' do
      it 'Removes field groups where all fields in group are empty' do
        generate_csv(test_csv, rows)
        result = execute_job(filename: test_csv,
                             xform: Clean::EmptyFieldGroups,
                             xformopt: {
                               groups: [
                                 %i[a1 a2],
                                 %i[b1 b2 b3]
                               ],
                               sep: ';',
                               use_nullvalue: true
                             })
      expected = [
        {:id=>'4',
         :a1=>'not',
         :a2=>nil,
         :b1=>'empty',
         :b2=>'empty',
         :b3=>'empty'
        },
        {:id=>'1',
         :a1=>'not;empty',
         :a2=>'not;empty',
         :b1=>'not;empty',
         :b2=>'not;empty',
         :b3=>'not;empty'
        },
        {:id=>'2',
         :a1=>'not',
         :a2=>'not',
         :b1=>'%NULLVALUE%;empty',
         :b2=>'not;empty',
         :b3=>'%NULLVALUE%;empty'
        },
        {:id=>'3',
         :a1=>nil,
         :a2=>nil,
         :b1=>'empty',
         :b2=>'empty',
         :b3=>'empty'
        },
        {:id=>'5',
         :a1=>nil,
         :a2=>nil,
         :b1=>'not;empty',
         :b2=>'%NULLVALUE%;empty',
         :b3=>'empty;%NULLVALUE%'
        },
        {:id=>'6',
         :a1=>nil,
         :a2=>nil,
         :b1=>'empty',
         :b2=>'empty',
         :b3=>'empty'
        }
      ]
        expect(result).to eq(expected)
      end
    end
  end
  
  describe 'RegexpFindReplaceFieldVals' do
    test_csv = 'tmp/test.csv'
    
    after { File.delete(test_csv) if File.exist?(test_csv) }
    it 'Does specified regexp find/replace in field values' do
      rows = [
        ['id', 'val'],
        ['1', 'xxxxxx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: {fields: [:val],
                                      find: 'xx+',
                                      replace: 'exes'}).map{ |h| h[:val] }.join('; ')
      expected = 'exes a thing; thing exes 123; x files'
      expect(result).to eq(expected)
    end

    it 'Handles beginning/ending of string anchors' do
      rows = [
        ['id', 'val'],
        ['1', 'xxxxxx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: {fields: [:val],
                                      find: '^xx+',
                                      replace: 'exes'}).map{ |h| h[:val] }.join('; ')
      expected = 'exes a thing; thing xxxx 123; x files'
      expect(result).to eq(expected)
    end

    it 'Can be made case insensitive' do
      rows = [
        ['id', 'val'],
        ['1', 'the thing'],
        ['2', 'The Thing']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: {fields: [:val],
                                      find: 'thing',
                                      replace: 'object',
                                      casesensitive: false}).map{ |h| h[:val] }.join('; ')
      expected = 'the object; The object'
      expect(result).to eq(expected)
    end

    it 'handles capture groups' do
      rows = [
        ['id', 'val'],
        ['1', 'a thing']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: {fields: [:val],
                                      find: '^(a) (thing)',
                                      replace: 'about \1 curious \2'}).map{ |h| h[:val] }.join('; ')
      expected = 'about a curious thing'
      expect(result).to eq(expected)
    end

    it 'returns nil if replacement creates empty string' do
      rows = [
        ['id', 'val'],
        ['1', 'xxxxxx']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: {fields: [:val],
                                      find: 'xx+',
                                      replace: ''}).map{ |h| h[:val] }
      expected = [nil]
      expect(result).to eq(expected)
    end

    it 'supports specifying multiple fields to do the find/replace in' do
      rows = [
        ['id', 'val', 'another'],
        ['1', 'xxxxxx1', 'xxx2xxxxx']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: {fields: [:val, :another],
                                      find: 'xx+',
                                      replace: ''}).map{ |h| "#{h[:val]} #{h[:another]}" }
      expected = ['1 2']
      expect(result).to eq(expected)
    end

    context 'when debug = true option is specified' do
      it 'creates new field with `_repl` suffix instead of doing change in place' do
        rows = [
          ['id', 'val'],
          ['1', 'xxxx1']
        ]
        generate_csv(test_csv, rows)
        result = execute_job(filename: test_csv,
                             xform: Clean::RegexpFindReplaceFieldVals,
                             xformopt: {fields: [:val],
                                        find: 'xx+',
                                        replace: '',
                                        debug: true}).map{ |h| "#{h[:val]} #{h[:val_repl]}" }
        expected = ['xxxx1 1']
        expect(result).to eq(expected)
      end
    end

    context 'when multival = true option and sep are specified' do
      it 'splits field into multiple values and applies find/replace to each value' do
        rows = [
            ['id', 'val'],
            ['1', 'bats;bats']
          ]
          generate_csv(test_csv, rows)
          result = execute_job(filename: test_csv,
                               xform: Clean::RegexpFindReplaceFieldVals,
                               xformopt: {fields: [:val],
                                          find: 's$',
                                          replace: '',
                                          multival: true,
                                          sep: ';'}).map{ |h| h[:val] }
          expected = ['bat;bat']
          expect(result).to eq(expected)
        end
      end
  end

  describe 'StripFields' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'val'],
      ['1', ' blah '],
      ['2', 'blah'],
      ['3', nil],
      ['4', '']
    ]
    
    before { generate_csv(test_csv, rows) }
    let(:result) { execute_job(filename: test_csv, xform: Clean::StripFields, xformopt: {fields: %i[val]}) }
    it 'strips field value' do
      expected = [
        {id: '1', val: 'blah'},
        {id: '2', val: 'blah'},
        {id: '3', val: nil},
        {id: '4', val: nil}
      ]
      expect(result).to eq(expected)
    end
  end
end
