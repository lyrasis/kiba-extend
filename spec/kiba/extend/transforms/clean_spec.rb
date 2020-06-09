require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Clean do
  describe 'DelimiterOnlyFields' do
    test_csv = 'tmp/test.csv'
    rows = [
        ['id', 'in_set'],
        ['1', 'a; b'],
        ['2', ';'],
        ['3', nil]
      ]
    
      before { generate_csv(test_csv, rows) }
      let(:result) { execute_job(filename: test_csv, xform: Clean::DelimiterOnlyFields, xformopt: {delim: ';'}) }
      it 'changes delimiter only fields to nil' do
        expect(result[1][:in_set]).to be_nil
      end
      it 'leaves other fields unchanged' do
        expect(result[0][:in_set]).to eq('a; b')
        expect(result[2][:in_set]).to be_nil
      end
      after { File.delete(test_csv) if File.exist?(test_csv) }
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
    test_csv = 'tmp/test.csv'
    
    after { File.delete(test_csv) if File.exist?(test_csv) }
    it 'Removes field groups where all fields in group are empty' do
      rows = [
        ['id', 'a1', 'a2', 'b1', 'b2', 'b3'],
        ['4', 'not;', nil, ';empty', ';empty', ';empty'],
        ['1', 'not;empty', 'not;empty', 'not;empty', 'not;empty', 'not;empty'],
        ['2', 'not;', 'not;', ';empty', 'not;empty', ';empty'],
        ['3', ';', ';', ';empty', ';empty', ';empty']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::EmptyFieldGroups,
                           xformopt: {
                             groups: [
                               %i[a1 a2],
                               %i[b1 b2 b3]
                             ],
                             sep: ';'
                           })
      expected = [
        {:id=>'4',
         :a1=>'not;',
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
      ]
      expect(result).to eq(expected)
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
end
