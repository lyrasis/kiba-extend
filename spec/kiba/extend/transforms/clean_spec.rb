require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Clean do
  describe 'DelimiterOnlyFields' do
    test_csv = 'tmp/test.csv'
    rows = [
        ['id', 'in_set'],
        ['1', 'a; b'],
        ['2', ';']
      ]
    
    describe '#process' do
      before { generate_csv(test_csv, rows) }
      let(:result) { execute_job(filename: test_csv, xform: Clean::DelimiterOnlyFields, xformopt: {delim: ';'}) }
      it 'changes delimiter only fields to nil' do
        expect(result[1][:in_set]).to be_nil
      end
      it 'leaves other fields unchanged' do
        expect(result[0][:in_set]).to eq('a; b')
      end
      after { File.delete(test_csv) if File.exist?(test_csv) }
    end
  end

    describe 'RegexpFindReplaceFieldVals' do
    test_csv = 'tmp/test.csv'
    
    describe '#process' do
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
    end
    end
end
