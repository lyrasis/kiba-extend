require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Reshape do
  describe 'CollapseMultipleFieldsToOneTypedFieldPair' do
    test_csv = 'tmp/test.csv'
    context 'when source field may be multivalued' do
      rows = [
        ['homephone', 'workphone', 'mobilephone', 'otherphone', 'unrelated'],
        ['2', '1', '3;4', '5', 'foo']
      ]
      before do
        generate_csv(test_csv, rows)
      end
      it 'reshapes the columns as specified after splitting source' do
        expected = [
          {phoneNumber: '1;2;3;4;5', phoneType: 'business;personal;mobile;mobile;', unrelated: 'foo'}
        ]
        result = execute_job(filename: test_csv,
                             xform: Reshape::CollapseMultipleFieldsToOneTypedFieldPair,
                             xformopt: {sourcefieldmap: {
                               workphone: 'business',
                               homephone: 'personal',
                               mobilephone: 'mobile',
                               otherphone: ''
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
        ['workphone', 'homephone', 'mobilephone', 'otherphone', 'unrelated'],
        ['123', '234', '345;456', '567', 'foo'],
        ['123', '234', '345 456', '567', 'bar']
      ]
      before do
        generate_csv(test_csv, rows)
      end
      it 'reshapes the columns as specified' do
        expected = [
          {phoneNumber: '123;234;345;456;567', phoneType: 'business;personal;mobile;', unrelated: 'foo'},
          {phoneNumber: '123;234;345 456;567', phoneType:'business;personal;mobile;', unrelated: 'bar'}
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
