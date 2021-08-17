# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiba::Extend::Transforms::Delete do
  describe 'EmptyFieldValues' do
    rows = [
      %w[id data],
      [1, 'abc;;;d e f'],
      [2, ';;abc'],
      [3, 'def;;;;'],
      [4, ';;;;;']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'deletes empty field values from multivalued field' do
      expected = [
        { id: '1', data: 'abc;d e f' },
        { id: '2', data: 'abc' },
        { id: '3', data: 'def' },
        { id: '4', data: '' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Delete::EmptyFieldValues,
                           xformopt: { fields: [:data], sep: ';' })
      expect(result).to eq(expected)
    end
  end

  describe 'Fields' do
    rows = [
      %w[id name sex source],
      [1, 'Weddy', 'm', 'adopted'],
      [2, 'Kernel', 'f', 'adopted']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'deletes fields' do
      expected = [
        { id: '1', name: 'Weddy' },
        { id: '2', name: 'Kernel' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Delete::Fields,
                           xformopt: { fields: %i[sex source] })
      expect(result).to eq(expected)
    end
  end

  describe 'FieldsExcept' do
    rows = [
      %w[id name sex source],
      [1, 'Weddy', 'm', 'adopted'],
      [2, 'Kernel', 'f', 'adopted']
    ]

    before do
      generate_csv(test_csv, rows)
    end
    it 'deletes all fields except ones given as keepfields' do
      expected = [
        { name: 'Weddy' },
        { name: 'Kernel' }
      ]
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldsExcept,
                           xformopt: { keepfields: %i[name] })
      expect(result).to eq(expected)
    end
  end

  describe 'FieldValueMatchingRegexp' do
    after { File.delete(test_csv) if File.exist?(test_csv) }
    it 'Deletes whole field value if it matches given regexp' do
      rows = [
        %w[id val],
        ['1', 'xxxxxx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueMatchingRegexp,
                           xformopt: { fields: [:val],
                                       match: 'xx+' }).map { |h| h[:val] }
      expected = [nil, nil, 'x files']
      expect(result).to eq(expected)
    end
    it 'Can do case insensitive match' do
      rows = [
        %w[id val],
        ['1', 'XxXx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueMatchingRegexp,
                           xformopt: { fields: [:val],
                                       match: '^xxxx ',
                                       casesensitive: false }).map { |h| h[:val] }
      expected = [nil, 'thing xxxx 123', 'x files']
      expect(result).to eq(expected)
    end
    it 'Skips nil values' do
      rows = [
        %w[id val],
        ['1', 'XxXx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', nil]
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueMatchingRegexp,
                           xformopt: { fields: [:val],
                                       match: 'xxxx ',
                                       casesensitive: false }).map { |h| h[:val] }
      expected = [nil, nil, nil]
      expect(result).to eq(expected)
    end
  end

  describe 'FieldValueIfEqualsOtherField' do
    after { File.delete(test_csv) if File.exist?(test_csv) }
    it 'deletes data in specified field if it duplicates data in other given field' do
      rows2 = [
        %w[id val chk],
        [1, 'a', 'b'],
        [2, 'c', 'c']
      ]
      generate_csv(test_csv, rows2)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueIfEqualsOtherField,
                           xformopt: {
                             delete: :val,
                             if_equal_to: :chk
                           }).map { |h| h[:val] }
      expected = ['a', '']
      expect(result).to eq(expected)
    end

    context 'when `multival` = true and `sep` given' do
      it 'deletes individual value matching `if_equal_to` field' do
        rows2 = [
          %w[id val chk],
          [1, 'a', 'b'],
          [2, 'a;c', 'c']
        ]
        generate_csv(test_csv, rows2)
        result = execute_job(filename: test_csv,
                             xform: Delete::FieldValueIfEqualsOtherField,
                             xformopt: {
                               delete: :val,
                               if_equal_to: :chk,
                               multival: true,
                               sep: ';'
                             }).map { |h| h[:val] }
        expected = %w[a a]
        expect(result).to eq(expected)
      end
    end

    context 'when `grouped_fields` given' do
      it 'deletes corresponding values from grouped fields' do
        rows2 = [
          %w[id val chk valgrp valgrp2],
          [2, 'a;C;d;c;e', 'c', 'y;x;w;u;v', 'e;f;g;h;i'],
          [1, 'a', 'b', 'z', 'q']
        ]
        generate_csv(test_csv, rows2)
        result = execute_job(filename: test_csv,
                             xform: Delete::FieldValueIfEqualsOtherField,
                             xformopt: {
                               delete: :val,
                               if_equal_to: :chk,
                               multival: true,
                               sep: ';',
                               grouped_fields: %i[valgrp valgrp2],
                               case_sensitive: false
                             })
        expected = [
          { id: '2', val: 'a;d;e', chk: 'c', valgrp: 'y;w;v', valgrp2: 'e;g;i' },
          { id: '1', val: 'a', chk: 'b', valgrp: 'z', valgrp2: 'q' }
        ]
        expect(result).to eq(expected)
      end
    end
  end

  describe 'FieldValueContainingString' do
    after { File.delete(test_csv) if File.exist?(test_csv) }
    it 'Deletes whole field value if it contains given string' do
      rows = [
        %w[id val],
        ['1', 'xxxx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueContainingString,
                           xformopt: { fields: [:val],
                                       match: ' xxxx ' }).map { |h| h[:val] }
      expected = ['xxxx a thing', nil, 'x files']
      expect(result).to eq(expected)
    end
    it 'Can do case insensitive match' do
      rows = [
        %w[id val],
        ['1', 'XxXx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', 'x files']
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueContainingString,
                           xformopt: { fields: [:val],
                                       match: 'xxxx ',
                                       casesensitive: false }).map { |h| h[:val] }
      expected = [nil, nil, 'x files']
      expect(result).to eq(expected)
    end
    it 'Skips nil values' do
      rows = [
        %w[id val],
        ['1', 'XxXx a thing'],
        ['2', 'thing xxxx 123'],
        ['3', nil]
      ]
      generate_csv(test_csv, rows)
      result = execute_job(filename: test_csv,
                           xform: Delete::FieldValueContainingString,
                           xformopt: { fields: [:val],
                                       match: 'xxxx ',
                                       casesensitive: false }).map { |h| h[:val] }
      expected = [nil, nil, nil]
      expect(result).to eq(expected)
    end
  end
end
