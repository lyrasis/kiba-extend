# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Clean do
  let(:accumulator){ [] }
  let(:test_job){ Helpers::TestJob.new(input: input, accumulator: accumulator, transforms: transforms) }
  let(:result){ test_job.accumulator }

  describe 'AlphabetizeFieldValues' do
    let(:input) do
      [
        { type: 'Person;unmapped;Organization'},
        { type: ';'},
        { type: nil},
        { type: ''},
        { type: 'Person;notmapped'},
        { type: '%NULLVALUE%;apple'},
        { type: 'oatmeal;%NULLVALUE%'}
      ]
    end

    context 'when when usenull = false' do
      context 'when direction = :asc' do
        let(:transforms) do
          Kiba.job_segment do
            transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: false,
              direction: :asc
          end
        end
        
        it 'sorts as expected' do
          expected = [
            { type: 'Organization;Person;unmapped'},
            { type: ';'},
            { type: nil},
            { type: ''},
            { type: 'notmapped;Person'},
            { type: 'apple;%NULLVALUE%'},
            { type: '%NULLVALUE%;oatmeal'}
          ]
          expect(result).to eq(expected)
        end

        context 'when direction = :desc' do
          let(:transforms) do
            Kiba.job_segment do
              transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: false,
                direction: :desc
            end
          end
          
          it 'sorts as expected' do
            expected = [
              { type: 'unmapped;Person;Organization'},
              { type: ';'},
              { type: nil},
              { type: ''},
              { type: 'Person;notmapped'},
              { type: '%NULLVALUE%;apple'},
              { type: 'oatmeal;%NULLVALUE%'}
            ]
            expect(result).to eq(expected)
          end
        end
      end
    end

    context 'when usenull = true' do
      context 'when direction = :asc' do
        let(:transforms) do
          Kiba.job_segment do
            transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: true,
              direction: :asc
          end
        end

        it 'sorts as expected' do
          expected = [
            { type: 'Organization;Person;unmapped'},
            { type: ';'},
            { type: nil},
            { type: ''},
            { type: 'notmapped;Person'},
            { type: 'apple;%NULLVALUE%'},
            { type: 'oatmeal;%NULLVALUE%'}
          ]
          expect(result).to eq(expected)
        end
      end
      

      context 'when direction = :desc' do
        let(:transforms) do
          Kiba.job_segment do
            transform Clean::AlphabetizeFieldValues, fields: %i[type], delim: ';', usenull: true,
              direction: :desc
          end
        end

        it 'sorts as expected' do
          expected = [
            { type: 'unmapped;Person;Organization'},
            { type: ';'},
            { type: nil},
            { type: ''},
            { type: 'Person;notmapped'},
            { type: '%NULLVALUE%;apple'},
            { type: '%NULLVALUE%;oatmeal'}
          ]
          expect(result).to eq(expected)
        end
      end
    end
  end

  describe 'ClearFields' do
    rows = [
      %w[id type],
      ['1', 'Person;unmapped;Organization'],
      ['2', ';'],
      ['3', nil],
      ['4', ''],
      ['5', 'Person;notmapped']
    ]

    before { generate_csv(rows) }
    context 'without additional arguments' do
      it 'sets the value of the field in all rows to nil' do
        result = execute_job(filename: test_csv,
                             xform: Clean::ClearFields,
                             xformopt: { fields: %i[type] })
        expect(result.map { |e| e[1] }.uniq[0]).to be_nil
      end
    end
    context 'with if_equals argument' do
      it 'sets the value of the field to nil if it matches `if_equals`' do
        result = execute_job(filename: test_csv,
                             xform: Clean::ClearFields,
                             xformopt: { fields: %i[type], if_equals: ';' })
        expect(result.map { |e| e[1] }.uniq[0]).to be_nil
      end
    end
  end

  describe 'DelimiterOnlyFields' do
    let(:rows) do
      [
        %w[id in_set],
        ['1', 'a; b'],
        ['2', ';'],
        ['3', nil],
        ['4', '%NULLVALUE%;%NULLVALUE%;%NULLVALUE%']
      ]
    end
    let(:result) { execute_job(filename: test_csv, xform: Clean::DelimiterOnlyFields, xformopt: options) }

    before { generate_csv(rows) }
    after { File.delete(test_csv) if File.exist?(test_csv) }

    context 'when use_nullvalue = false (the default)' do
      let(:options) { { delim: ';' } }
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
      let(:options) { { delim: ';', use_nullvalue: true } }
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
    after { File.delete(test_csv) if File.exist?(test_csv) }

    it 'downcases value(s) of specified field(s)' do
      rows = [
        %w[val x],
        %w[Aaa 123],
        ['Bbb', '']
      ]
      generate_csv(rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::DowncaseFieldValues,
                           xformopt: {
                             fields: %i[val x]
                           })
      expected = [
        { val: 'aaa', x: '123' },
        { val: 'bbb', x: '' }
      ]
      expect(result).to eq(expected)
    end
  end

  describe 'EmptyFieldGroups' do
    let(:rows) do
      [
        %w[id a1 a2 b1 b2 b3],
        ['4', 'not;', nil, ';empty', ';empty', ';empty'],
        ['1', 'not;empty', 'not;empty', 'not;empty', 'not;empty', 'not;empty'],
        ['2', 'not;', 'not;', ';empty', 'not;empty', ';empty'],
        ['3', ';', ';', ';empty', ';empty', ';empty'],
        ['5', '%NULLVALUE%;%NULLVALUE%', '%NULLVALUE%;%NULLVALUE%', 'not;empty', '%NULLVALUE%;empty',
         'empty;%NULLVALUE%'],
        ['6', ';', ';', '%NULLVALUE%;empty', '%NULLVALUE%;empty', '%NULLVALUE%;empty']
      ]
    end
    after { File.delete(test_csv) if File.exist?(test_csv) }

    context 'When use_nullvalue = false (the default)' do
      it 'Removes field groups where all fields in group are empty' do
        generate_csv(rows)
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
          { id: '4',
            a1: 'not',
            a2: nil,
            b1: 'empty',
            b2: 'empty',
            b3: 'empty' },
          { id: '1',
            a1: 'not;empty',
            a2: 'not;empty',
            b1: 'not;empty',
            b2: 'not;empty',
            b3: 'not;empty' },
          { id: '2',
            a1: 'not',
            a2: 'not',
            b1: ';empty',
            b2: 'not;empty',
            b3: ';empty' },
          { id: '3',
            a1: nil,
            a2: nil,
            b1: 'empty',
            b2: 'empty',
            b3: 'empty' },
          { id: '5',
            a1: '%NULLVALUE%;%NULLVALUE%',
            a2: '%NULLVALUE%;%NULLVALUE%',
            b1: 'not;empty',
            b2: '%NULLVALUE%;empty',
            b3: 'empty;%NULLVALUE%' },
          { id: '6',
            a1: nil,
            a2: nil,
            b1: '%NULLVALUE%;empty',
            b2: '%NULLVALUE%;empty',
            b3: '%NULLVALUE%;empty' }
        ]
        expect(result).to eq(expected)
      end
    end
    context 'When use_nullvalue = true' do
      it 'Removes field groups where all fields in group are empty' do
        generate_csv(rows)
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
          { id: '4',
            a1: 'not',
            a2: nil,
            b1: 'empty',
            b2: 'empty',
            b3: 'empty' },
          { id: '1',
            a1: 'not;empty',
            a2: 'not;empty',
            b1: 'not;empty',
            b2: 'not;empty',
            b3: 'not;empty' },
          { id: '2',
            a1: 'not',
            a2: 'not',
            b1: '%NULLVALUE%;empty',
            b2: 'not;empty',
            b3: '%NULLVALUE%;empty' },
          { id: '3',
            a1: nil,
            a2: nil,
            b1: 'empty',
            b2: 'empty',
            b3: 'empty' },
          { id: '5',
            a1: nil,
            a2: nil,
            b1: 'not;empty',
            b2: '%NULLVALUE%;empty',
            b3: 'empty;%NULLVALUE%' },
          { id: '6',
            a1: nil,
            a2: nil,
            b1: 'empty',
            b2: 'empty',
            b3: 'empty' }
        ]
        expect(result).to eq(expected)
      end
    end
  end

  describe 'RegexpFindReplaceFieldVals' do
    after { File.delete(test_csv) if File.exist?(test_csv) }
    it 'Does specified regexp find/replace in field values' do
      rows = [
        %w[id val],
        ['1', 'xxxxxx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: { fields: :val,
                                       find: 'xx+',
                                       replace: 'exes' }).map { |h| h[:val] }.join('; ')
      expected = 'exes a thing; thing exes 123; x files'
      expect(result).to eq(expected)
    end

    it 'Handles beginning/ending of string anchors' do
      rows = [
        %w[id val],
        ['1', 'xxxxxx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: { fields: [:val],
                                       find: '^xx+',
                                       replace: 'exes' }).map { |h| h[:val] }.join('; ')
      expected = 'exes a thing; thing xxxx 123; x files'
      expect(result).to eq(expected)
    end

    it 'Can be made case insensitive' do
      rows = [
        %w[id val],
        ['1', 'the thing'],
        ['2', 'The Thing']
      ]
      generate_csv(rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: { fields: [:val],
                                       find: 'thing',
                                       replace: 'object',
                                       casesensitive: false }).map { |h| h[:val] }.join('; ')
      expected = 'the object; The object'
      expect(result).to eq(expected)
    end

    it 'handles capture groups' do
      rows = [
        %w[id val],
        ['1', 'a thing']
      ]
      generate_csv(rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: { fields: [:val],
                                       find: '^(a) (thing)',
                                       replace: 'about \1 curious \2' }).map { |h| h[:val] }.join('; ')
      expected = 'about a curious thing'
      expect(result).to eq(expected)
    end

    it 'returns nil if replacement creates empty string' do
      rows = [
        %w[id val],
        %w[1 xxxxxx]
      ]
      generate_csv(rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: { fields: [:val],
                                       find: 'xx+',
                                       replace: '' }).map { |h| h[:val] }
      expected = [nil]
      expect(result).to eq(expected)
    end

    it 'supports specifying multiple fields to do the find/replace in' do
      rows = [
        %w[id val another],
        %w[1 xxxxxx1 xxx2xxxxx]
      ]
      generate_csv(rows)
      result = execute_job(filename: test_csv,
                           xform: Clean::RegexpFindReplaceFieldVals,
                           xformopt: { fields: %i[val another],
                                       find: 'xx+',
                                       replace: '' }).map { |h| "#{h[:val]} #{h[:another]}" }
      expected = ['1 2']
      expect(result).to eq(expected)
    end

    context 'when debug = true option is specified' do
      it 'creates new field with `_repl` suffix instead of doing change in place' do
        rows = [
          %w[id val],
          %w[1 xxxx1]
        ]
        generate_csv(rows)
        result = execute_job(filename: test_csv,
                             xform: Clean::RegexpFindReplaceFieldVals,
                             xformopt: { fields: [:val],
                                         find: 'xx+',
                                         replace: '',
                                         debug: true }).map { |h| "#{h[:val]} #{h[:val_repl]}" }
        expected = ['xxxx1 1']
        expect(result).to eq(expected)
      end
    end

    context 'when multival = true option and sep are specified' do
      it 'splits field into multiple values and applies find/replace to each value' do
        rows = [
          %w[id val],
          ['1', 'bats;bats']
        ]
        generate_csv(rows)
        result = execute_job(filename: test_csv,
                             xform: Clean::RegexpFindReplaceFieldVals,
                             xformopt: { fields: [:val],
                                         find: 's$',
                                         replace: '',
                                         multival: true,
                                         sep: ';' }).map { |h| h[:val] }
        expected = ['bat;bat']
        expect(result).to eq(expected)
      end
    end
  end

  describe 'StripFields' do
    rows = [
      %w[id val],
      ['1', ' blah '],
      %w[2 blah],
      ['3', nil],
      ['4', '']
    ]

    before { generate_csv(rows) }
    let(:result) { execute_job(filename: test_csv, xform: Clean::StripFields, xformopt: { fields: %i[val] }) }
    it 'strips field value' do
      expected = [
        { id: '1', val: 'blah' },
        { id: '2', val: 'blah' },
        { id: '3', val: nil },
        { id: '4', val: nil }
      ]
      expect(result).to eq(expected)
    end
  end
end
