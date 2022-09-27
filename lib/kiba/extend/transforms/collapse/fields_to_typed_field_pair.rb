# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Collapse
        # @since 2.9.0
        #
        # Takes multiple fields like :workphone, :homephone, :mobilephone and produces two new fields like :phone and :phonetype where :phonetype depends on the original field taken from
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | work | home     | mobile | other | name |
        # |------+----------+--------+-------+------|
        # | 123  | 456      | 789    | 897   | Sue  |
        # |      | 987;555  |        | 253   | Bob  |
        # | nil  |          |        | nil   | Mae  |
        # | 654  | 321      | 257    |       | Sid  |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Collapse::FieldsToTypedFieldPair,
        #    sourcefieldmap: { home: 'h', work: 'b', mobile: 'm', other: '' },
        #    datafield: :phone,
        #    typefield: :phonetype,
        #    sourcesep: ';',
        #    targetsep: '^',
        #    delete_sources: false
        # ```
        #
        # Results in:
        #
        # ```
        # | work | home     | mobile | other | phone           | phonetype | name |
        # |------+----------+--------+-------|-----------------+-----------+------|
        # | 123  | 456      | 789    | 897   | 456^123^789^897 | h^b^m^    | Sue  |
        # |      | 987;555  |        | 253   | 987^555^253     | h^h^      | Bob  |
        # | nil  |          |        | nil   | nil             | nil       | Mae  |
        # | 654  | 321      | 257    |       | 321^654^257     | h^b^m     | Sid  |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Collapse::FieldsToTypedFieldPair,
        #    sourcefieldmap: { home: 'h', work: 'b', mobile: '', other: 'o' },
        #    datafield: :phone,
        #    typefield: :phonetype,
        #    targetsep: '^'
        # ```
        #
        # Results in:
        #
        # ```
        # | phone           | phonetype | name |
        # |-----------------+-----------+------|
        # | 456^123^789^897 | h^b^m^    | Sue  |
        # | 987;555^253     | h^        | Bob  |
        # | nil             | nil       | Mae  |
        # | 321^654^257     | h^b^m     | Sid  |
        # ```
        #
        # ## Notice
        #
        # * The number of values in `phone` and `phonetype` are kept even
        # * The data in the target fields is in the order of the keys in the `sourcefieldmap`: home, work, mobile, other.
        class FieldsToTypedFieldPair
          # @param sourcefieldmap [Hash{Symbol => String}] Keys are the names of the source fields. Each key's value is the type that should be assigned in `typefield`
          # @param datafield [Symbol] Target field into which the original data value(s) from source fields will be mapped
          # @param typefield [Symbol] Target field into which the type values will be mapped
          # @param sourcesep [String] Delimiter used to split source data into multiple values
          # @param targetsep [String] Delimiter used to join multiple values in target fields
          # @param delete_sources [Boolean] Whether to delete source fields after mapping them to target fields
          def initialize(sourcefieldmap:, datafield:, typefield:, targetsep:, sourcesep: nil, delete_sources: true)
            @map = sourcefieldmap
            @df = datafield
            @tf = typefield
            @sourcesep = sourcesep
            @targetsep = targetsep
            @del = delete_sources
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            data = []
            type = []
            @map.each_key do |sourcefield|
              vals = row.fetch(sourcefield)
              unless vals.nil?
                vals = @sourcesep.nil? ? [vals] : vals.split(@sourcesep)
                vals.each do |val|
                  data << val
                  type << @map.fetch(sourcefield, @default_type)
                end
              end
              row.delete(sourcefield) if @del
            end
            row[@df] = data.size.positive? ? data.join(@targetsep) : nil
            row[@tf] = type.size.positive? ? type.join(@targetsep) : nil
            row
          end
        end
      end
    end
  end
end
