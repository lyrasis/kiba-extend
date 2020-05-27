require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::CombineValues do
  describe 'FromFieldsWithDelimiter' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'name', 'sex', 'source'],
      [1, 'Weddy', 'm', 'adopted'],
      [2, 'Kernel', 'f', 'adopted']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'concatenates specified field values into new column with specified separator' do
      expected = [
        {:id=>'1', :newcol=>'Weddy --- m --- adopted',},
        {:id=>'2', :newcol=>'Kernel --- f --- adopted'},
      ]
      result = execute_job(filename: test_csv,
                           xform: CombineValues::FromFieldsWithDelimiter,
                           xformopt: {sources: [:name, :sex, :source],
                                      target: :newcol,
                                      sep: ' --- '})
      expect(result).to eq(expected)
    end

    context 'when `prepend_source_field_name` set to true' do
      it 'concatenates specified field values into new column with specified separator' do
        expected = [
          {:id=>'1', :newcol=>'name: Weddy --- sex: m --- source: adopted',},
          {:id=>'2', :newcol=>'name: Kernel --- sex: f --- source: adopted'},
        ]
        result = execute_job(filename: test_csv,
                             xform: CombineValues::FromFieldsWithDelimiter,
                             xformopt: {sources: [:name, :sex, :source],
                                        target: :newcol,
                                        sep: ' --- ',
                                        prepend_source_field_name: true},)
        expect(result).to eq(expected)
      end
      context 'when there are blank/nil fields' do
        rows2 = [
          ['id', 'name', 'sex', 'source'],
          [1, 'Weddy', '', 'adopted'],
          [2, 'Kernel', 'f', 'adopted']
        ]
        before { generate_csv(test_csv, rows2) }
        
        it 'does not include blank or nil fields' do
          expected = [
            {:id=>'1', :newcol=>'name: Weddy --- source: adopted',},
            {:id=>'2', :newcol=>'name: Kernel --- sex: f --- source: adopted'},
          ]
          result = execute_job(filename: test_csv,
                               xform: CombineValues::FromFieldsWithDelimiter,
                               xformopt: {sources: [:name, :sex, :source],
                                          target: :newcol,
                                          sep: ' --- ',
                                          prepend_source_field_name: true},)
          expect(result).to eq(expected)
        end
      end
    end
    
    context 'when `delete_sources` set to false' do
      it 'adds the new column but does not remove original columns' do
        expected = [
          {:id=>'1', :name => 'Weddy', :sex => 'm', :source => 'adopted', :newcol=>'Weddy|m|adopted',},
          {:id=>'2', :name => 'Kernel', :sex => 'f', :source => 'adopted', :newcol=>'Kernel|f|adopted'},
        ]
        result = execute_job(filename: test_csv,
                             xform: CombineValues::FromFieldsWithDelimiter,
                             xformopt: {sources: [:name, :sex, :source],
                                        target: :newcol,
                                        sep: '|',
                                        delete_sources: false})
        expect(result).to eq(expected)
      end
    end
  end
end
