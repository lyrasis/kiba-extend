require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Delete do
  describe 'Fields' do
    test_csv = 'tmp/test.csv'
    rows = [
      ['id', 'name', 'sex', 'source'],
      [1, 'Weddy', 'm', 'adopted'],
      [2, 'Kernel', 'f', 'adopted']
    ]

    describe '#process' do
      before do
        generate_csv(test_csv, rows)
      end
      it 'concatenates specified field values into new column with specified separator' do
        expected = [
          {:id=>'1', :name=>'Weddy'},
          {:id=>'2', :name=>'Kernel'}
        ]
        result = execute_job(filename: test_csv,
                             xform: Delete::Fields,
                             xformopt: {fields: [:sex, :source]})
        expect(result).to eq(expected)
      end
    end
  end

  describe 'FieldValueMatchingRegexp' do
    test_csv = 'tmp/test.csv'
    after { File.delete(test_csv) if File.exist?(test_csv) }
    it 'Deletes whole field value if it matches given regexp' do
      rows = [
        ['id', 'val'],
        ['1', 'xxxxxx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueMatchingRegexp,
                           xformopt: {fields: [:val],
                                      match: 'xx+'}).map{ |h| h[:val] }
      expected = [nil, nil, 'x files']
      expect(result).to eq(expected)
    end
    it 'Can do case insensitive match' do
      rows = [
        ['id', 'val'],
        ['1', 'XxXx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueMatchingRegexp,
                           xformopt: {fields: [:val],
                                      match: '^xxxx ',
                                      casesensitive: false}).map{ |h| h[:val] }
      expected = [nil, 'thing xxxx 123', 'x files']
      expect(result).to eq(expected)
    end
    it 'Skips nil values' do
      rows = [
        ['id', 'val'],
        ['1', 'XxXx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', nil]
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueMatchingRegexp,
                           xformopt: {fields: [:val],
                                      match: 'xxxx ',
                                      casesensitive: false}).map{ |h| h[:val] }
      expected = [nil, nil, nil]
      expect(result).to eq(expected)
    end
  end

  describe 'FieldValueContainingString' do
    test_csv = 'tmp/test.csv'
    after { File.delete(test_csv) if File.exist?(test_csv) }
    it 'Deletes whole field value if it contains given string' do
      rows = [
        ['id', 'val'],
        ['1', 'xxxx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueContainingString,
                           xformopt: {fields: [:val],
                                      match: ' xxxx '}).map{ |h| h[:val] }
      expected = ['xxxx a thing', nil, 'x files']
      expect(result).to eq(expected)
    end
    it 'Can do case insensitive match' do
      rows = [
        ['id', 'val'],
        ['1', 'XxXx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueContainingString,
                           xformopt: {fields: [:val],
                                      match: 'xxxx ',
                                      casesensitive: false}).map{ |h| h[:val] }
      expected = [nil, nil, 'x files']
      expect(result).to eq(expected)
    end
    it 'Skips nil values' do
      rows = [
        ['id', 'val'],
        ['1', 'XxXx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', nil]
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueContainingString,
                           xformopt: {fields: [:val],
                                      match: 'xxxx ',
                                      casesensitive: false}).map{ |h| h[:val] }
      expected = [nil, nil, nil]
      expect(result).to eq(expected)
    end
  end
end
