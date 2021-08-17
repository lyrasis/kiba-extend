# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::CombineValues do
  describe 'AcrossFieldGroup' do
    rows = [
      %w[person statusa date personb statusb date2 personc statusc date3],
      %w[jim approved 2020 bill requested 2019 terri authorized 2018],
      ['jim;mavis', 'approved;', '2020;2021', 'bill', 'requested', '2019', 'terri', 'authorized', '2018'],
      [nil, 'acknowledged', '2020', 'jill', 'requested', nil, 'bill', 'followup', '2021'],
      ['%NULLVALUE%;%NULLVALUE%', 'acknowledged;approved', '2020;%NULLVALUE%', 'jill', 'requested', nil, 'bill',
       'followup', '2019']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'concatenates specified field values, keeping field group integrity' do
      expected = [
        { person: 'jim;bill;terri',
          status: 'authorized;approved;requested',
          statusdate: '2020;2019;2018' },
        { person: 'jim;mavis;bill;terri',
          status: 'authorized;approved;;requested',
          statusdate: '2020;2021;2019;2018' },
        { person: ';jill;bill',
          status: 'followup;acknowledged;requested',
          statusdate: '2020;;2021' },
        { person: '%NULLVALUE%;%NULLVALUE%;jill;bill',
          status: 'followup;acknowledged;approved;requested',
          statusdate: '2020;%NULLVALUE%;;2019' }
      ]
      opts = {
        fieldmap: {
          person: %i[person personb personc],
          status: %i[statusc statusa statusb],
          statusdate: %i[date date2 date3]
        },
        sep: ';'
      }
      result = execute_job(filename: test_csv,
                           xform: CombineValues::AcrossFieldGroup,
                           xformopt: opts)
      expect(result).to eq(expected)
    end
  end

  describe 'FromFieldsWithDelimiter' do
    rows = [
      %w[id name sex source],
      [1, 'Weddy', 'm', 'adopted'],
      [2, 'Kernel', 'f', 'adopted'],
      [3, 'Earlybird', nil, 'hatched'],
      [4, '', '', '']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'concatenates specified field values into new column with specified separator' do
      expected = [
        { id: '1', newcol: 'Weddy --- m --- adopted' },
        { id: '2', newcol: 'Kernel --- f --- adopted' },
        { id: '3', newcol: 'Earlybird --- hatched' },
        { id: '4', newcol: nil }
      ]
      result = execute_job(filename: test_csv,
                           xform: CombineValues::FromFieldsWithDelimiter,
                           xformopt: { sources: %i[name sex source],
                                       target: :newcol,
                                       sep: ' --- ' })
      expect(result).to eq(expected)
    end

    context 'when `prepend_source_field_name` set to true' do
      it 'concatenates specified field values into new column with specified separator' do
        expected = [
          { id: '1', newcol: 'name: Weddy --- sex: m --- source: adopted' },
          { id: '2', newcol: 'name: Kernel --- sex: f --- source: adopted' },
          { id: '3', newcol: 'name: Earlybird --- source: hatched' },
          { id: '4', newcol: nil }
        ]
        result = execute_job(filename: test_csv,
                             xform: CombineValues::FromFieldsWithDelimiter,
                             xformopt: { sources: %i[name sex source],
                                         target: :newcol,
                                         sep: ' --- ',
                                         prepend_source_field_name: true })
        expect(result).to eq(expected)
      end
      context 'when there are blank/nil fields' do
        rows2 = [
          %w[id name sex source],
          [1, 'Weddy', '', 'adopted'],
          [2, 'Kernel', 'f', 'adopted']
        ]
        before { generate_csv(test_csv, rows2) }

        it 'does not include blank or nil fields' do
          expected = [
            { id: '1', newcol: 'name: Weddy --- source: adopted' },
            { id: '2', newcol: 'name: Kernel --- sex: f --- source: adopted' }
          ]
          result = execute_job(filename: test_csv,
                               xform: CombineValues::FromFieldsWithDelimiter,
                               xformopt: { sources: %i[name sex source],
                                           target: :newcol,
                                           sep: ' --- ',
                                           prepend_source_field_name: true })
          expect(result).to eq(expected)
        end
      end
    end

    context 'when `delete_sources` set to false' do
      it 'adds the new column but does not remove original columns' do
        expected = [
          { id: '1', name: 'Weddy', sex: 'm', source: 'adopted', newcol: 'Weddy|m|adopted' },
          { id: '2', name: 'Kernel', sex: 'f', source: 'adopted', newcol: 'Kernel|f|adopted' },
          { id: '3', name: 'Earlybird', sex: nil, source: 'hatched', newcol: 'Earlybird|hatched' },
          { id: '4', name: '', sex: '', source: '', newcol: nil }
        ]
        result = execute_job(filename: test_csv,
                             xform: CombineValues::FromFieldsWithDelimiter,
                             xformopt: { sources: %i[name sex source],
                                         target: :newcol,
                                         sep: '|',
                                         delete_sources: false })
        expect(result).to eq(expected)
      end
    end

    context 'when target field is one of the source fields' do
      it 'does not delete the target field' do
        expected = [
          { id: '1', name: 'Weddy|m', source: 'adopted' },
          { id: '2', name: 'Kernel|f', source: 'adopted' },
          { id: '3', name: 'Earlybird', source: 'hatched' },
          { id: '4', name: nil, source: '' }
        ]
        result = execute_job(filename: test_csv,
                             xform: CombineValues::FromFieldsWithDelimiter,
                             xformopt: { sources: %i[name sex],
                                         target: :name,
                                         sep: '|' })
        expect(result).to eq(expected)
      end
    end
  end

  describe 'FullRecord' do
    rows = [
      %w[name sex source],
      %w[Weddy m adopted],
      %w[Niblet f hatched],
      ['Keet', nil, 'hatched']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'concatenates all fields (with given delimiter) into given field' do
      expected = [
        { name: 'Weddy', sex: 'm', source: 'adopted',
          search: 'Weddy m adopted' },
        { name: 'Niblet', sex: 'f', source: 'hatched',
          search: 'Niblet f hatched' },
        { name: 'Keet', sex: nil, source: 'hatched',
          search: 'Keet hatched' }
      ]
      result = execute_job(filename: test_csv,
                           xform: CombineValues::FullRecord,
                           xformopt: { target: :search })
      expect(result).to eq(expected)
    end
  end
end
