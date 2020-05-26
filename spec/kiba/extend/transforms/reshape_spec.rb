require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Replace do
  describe 'CollapseMultipleFieldsToOneTypedFieldPair' do
    test_csv = 'tmp/test.csv'
    context 'when source field may be multivalued' do
      rows = [
        ['id', 'workphone', 'homephone', 'mobilephone', 'otherphone'],
        [1, '1', '2', '3;4', '5']
      ]
      before do
        generate_csv(test_csv, rows)
      end
      it 'reshapes the columns as specified after splitting source' do
        expected = [
          {:id=>'1', :phoneNumber=>'1;2;3;4;5', :phoneType=>'business;personal;mobile;mobile;'}
        ]
        result = execute_job(filename: test_csv,
                             xform: Reshape::CollapseMultipleFieldsToOneTypedFieldPair,
                             xformopt: {sourcefieldmap: {
                               :workphone => 'business',
                               :homephone => 'personal',
                               :mobilephone => 'mobile',
                               :otherphone => ''
                             },
                                        datafield: :phoneNumber,
                                        typefield: :phoneType,
                                        sourcesep: DELIM,
                                        targetsep: DELIM
                                       })
        expect(result).to eq(expected)
      end
    end
    context 'when source field is not multivalued' do
      rows = [
        ['id', 'workphone', 'homephone', 'mobilephone', 'otherphone'],
        [1, '123', '234', '345;456', '567'],
        [2, '123', '234', '345 456', '567']
      ]
      before do
        generate_csv(test_csv, rows)
      end
      it 'reshapes the columns as specified' do
        expected = [
          {:id=>'1', :phoneNumber=>'123;234;345;456;567', :phoneType=>'business;personal;mobile;'},
          {:id=>'2', :phoneNumber=>'123;234;345 456;567', :phoneType=>'business;personal;mobile;'}
        ]
        result = execute_job(filename: test_csv,
                             xform: Reshape::CollapseMultipleFieldsToOneTypedFieldPair,
                             xformopt: {sourcefieldmap: {
                               :workphone => 'business',
                               :homephone => 'personal',
                               :mobilephone => 'mobile',
                               :otherphone => ''
                             },
                                        datafield: :phoneNumber,
                                        typefield: :phoneType,
                                        targetsep: DELIM
                                       })
        expect(result).to eq(expected)
      end
    end
  end
end
