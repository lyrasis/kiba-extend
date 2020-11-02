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
      [2, 'Kernel', 'f'],
      [3, 'Earlybird;Earhart', 'f;f']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'adds field value from static mapping' do
      expected = [
        {id: '1', name: 'Weddy', gender: 'male'},
        {id: '2', name: 'Kernel', gender: 'female'},
        {id: '3', name: 'Earlybird;Earhart', gender: 'female;female'}
      ]
      result = execute_job(filename: test_csv,
                           xform: Replace::FieldValueWithStaticMapping,
                           xformopt: {source: :sex,
                                      target: :gender,
                                      mapping: mapping,
                                      multival: true,
                                      sep: ';'})
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
      context 'and :fallback_val = :orig (this is the default!)' do
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
      context 'and :fallback_val = :nil' do
        it 'sends nil through to new column' do
          expected = [
            {:id=>'1', :name=>'Unnamed keet', :gender=>nil},
            {:id=>'2', :name=>'Kernel', :gender=>'female'}
          ]
          result = execute_job(filename: test_csv,
                               xform: Replace::FieldValueWithStaticMapping,
                               xformopt: {source: :sex,
                                          target: :gender,
                                          mapping: mapping,
                                          fallback_val: :nil})
          expect(result).to eq(expected)
        end
      end
    end
  end
end
