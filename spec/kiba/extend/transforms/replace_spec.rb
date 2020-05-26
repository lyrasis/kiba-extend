require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Replace do
  describe 'FieldValueWithStaticMapping' do
    test_csv = 'tmp/test.csv'
    mapping = {
      'm' => 'male',
      'f' => 'female'
    }
    rows = [
      ['id', 'name', 'sex'],
      [1, 'Weddy', 'm'],
      [2, 'Kernel', 'f']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'adds field value from static mapping' do
      expected = [
        {:id=>'1', :name=>'Weddy', :gender=>'male'},
        {:id=>'2', :name=>'Kernel', :gender=>'female'}
      ]
      result = execute_job(filename: test_csv,
                           xform: Replace::FieldValueWithStaticMapping,
                           xformopt: {source: :sex,
                                      target: :gender,
                                      mapping: mapping})
      expect(result).to eq(expected)
    end
    context 'When mapping does not contain matching key' do
      rows2 = [
        ['id', 'name', 'sex'],
        [1, 'Unnamed keet', 'n'],
        [2, 'Kernel', 'f']
      ]
      before do
        generate_csv(test_csv, rows2)
      end
      it 'sends original value through to new column' do
        expected = [
          {:id=>'1', :name=>'Unnamed keet', :gender=>'n'},
          {:id=>'2', :name=>'Kernel', :gender=>'female'}
        ]
        result = execute_job(filename: test_csv,
                             xform: Replace::FieldValueWithStaticMapping,
                             xformopt: {source: :sex,
                                        target: :gender,
                                        mapping: mapping})
        expect(result).to eq(expected)
      end
    end
  end
end
