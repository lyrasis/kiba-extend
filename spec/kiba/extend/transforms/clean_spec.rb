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
    let(:input) do
      [
        {val: 'xxxxxx a thing'},
        {val: 'thing xxxx 123'},
        {val: 'x files'}
      ]
    end

    let(:expected) do
      [
        {val: 'exes a thing'},
        {val: 'thing exes 123'},
        {val: 'x files'}
      ]
    end

    let(:transforms) do
      Kiba.job_segment do
        transform Clean::RegexpFindReplaceFieldVals, fields: :val, find: 'xx+', replace: 'exes'
      end
    end

    it 'Does specified regexp find/replace in field values' do
      expect(result).to eq(expected)
    end

    context 'with start/end string anchors' do
      let(:transforms) do
        Kiba.job_segment do
          transform Clean::RegexpFindReplaceFieldVals, fields: [:val], find: '^xx+', replace: 'exes'
        end
      end
      
      let(:expected) do
        [
          {val: 'exes a thing'},
          {val: 'thing xxxx 123'},
          {val: 'x files'}
        ]
      end

    it 'Does specified regexp find/replace in field values' do
        expect(result).to eq(expected)
      end
    end

    context 'when case insensitive' do
      let(:input) do
        [
          {val: 'the thing'},
          {val: 'The Thing'}
        ]
      end
      
      let(:transforms) do
        Kiba.job_segment do
          transform Clean::RegexpFindReplaceFieldVals, fields: [:val], find: 'thing', replace: 'object', casesensitive: false
        end
      end
      
      let(:expected) do
        [
          {val: 'the object'},
          {val: 'The object'}
        ]
      end
      it 'Does specified regexp find/replace in field values' do
        expect(result).to eq(expected)
      end
    end

    context 'when replacing line breaks' do
      let(:input) do
        [
          {val: '\n pace/macgill'},
          {val: 'database number\n'}
        ]
      end
      
      let(:transforms) do
        Kiba.job_segment do
          transform Clean::RegexpFindReplaceFieldVals, fields: :val, find: '\\\\n', replace: ''
        end
      end
      
      let(:expected) do
        [
          {val: ' pace/macgill'},
          {val: 'database number'}
        ]
      end
      it 'Does specified regexp find/replace in field values' do
        expect(result).to eq(expected)
      end
    end

    context 'with capture groups' do
      let(:input) do
        [
          {val: 'a thing'}
        ]
      end

      let(:transforms) do
        Kiba.job_segment do
          transform Clean::RegexpFindReplaceFieldVals, fields: [:val], find: '^(a) (thing)', replace: 'about \1 curious \2'
        end
      end
      
      let(:expected) do
        [
          {val: 'about a curious thing'}
        ]
      end
      
      it 'Does specified regexp find/replace in field values' do
        expect(result).to eq(expected)
      end
    end

    context 'when replacement results in empty string' do
      let(:input) do
        [
          {val: 'xxxxxx'}
        ]
      end
      
      let(:transforms) do
        Kiba.job_segment do
          transform Clean::RegexpFindReplaceFieldVals, fields: [:val], find: 'xx+', replace: ''
        end
      end
      
      let(:expected){ [{val: nil}] }
      
      it 'sets field value to nil' do
        expect(result).to eq(expected)
      end
    end

    context 'when multiple fields are given' do
      let(:input) do
        [
          {val: 'xxxxxx1', another: 'xxx2xxxxx'}
        ]
      end

      let(:transforms) do
        Kiba.job_segment do
          transform Clean::RegexpFindReplaceFieldVals, fields: %i[val another], find: 'xx+', replace: ''
        end
      end
      
      let(:expected){ [{val: '1', another: '2'}] }
      it 'Does specified regexp find/replace in field values' do
        expect(result).to eq(expected)
      end
    end

    context 'when fields = :all' do
      let(:input) do
        [
          {val: 'xxxxxx1', another: 'xxx2xxxxx'},
          {val: 10, another: nil}
        ]
      end

      let(:transforms) do
        Kiba.job_segment do
          transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: 'xx+', replace: ''
        end
      end
      
      let(:expected){ [{val: '1', another: '2'}, {val: 10, another: nil}] }
      it 'Does specified regexp find/replace in field values' do
        expect(result).to eq(expected)
      end
    end

    context 'when debug = true option is specified' do
      let(:input) do
        [
          {val: 'xxxx1'}
        ]
      end

      let(:transforms) do
        Kiba.job_segment do
          transform Clean::RegexpFindReplaceFieldVals, fields: [:val], find: 'xx+', replace: '', debug: true
        end
      end
      
      let(:expected){ [{val: 'xxxx1', val_repl: '1'}] }
      
      it 'creates new field with `_repl` suffix instead of doing change in place' do
        expect(result).to eq(expected)
      end
    end

    context 'when multival = true option and sep are specified' do
      let(:input) do
        [
          {val: 'bats;bats'}
        ]
        end

      let(:transforms) do
        Kiba.job_segment do
          transform Clean::RegexpFindReplaceFieldVals, fields: [:val], find: 's$', replace: '', multival: true, sep: ';'
        end
      end
      
      let(:expected){ [{val: 'bat;bat'}] }
      
      it 'splits field into multiple values and applies find/replace to each value' do
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
