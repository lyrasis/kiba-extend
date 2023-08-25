# frozen_string_literal: true

require "measured"

module Kiba
  module Extend
    module Transforms
      module Append
        # Converts a given measurement to a different unit and appends the
        #   converted value and unit to the original value and unit fields.
        #
        # @note Currently does **NOT** work for multivalue value/unit fields.
        #   Will return the original values if the given `delim` parameter
        #   value is present in either value or unit field
        #
        # This transform makes a number of strong assumptions, largely based on
        #   CollectionSpace data migration needs. The major ones, which are not
        #   overrideable via parameters, include:
        #
        # - one field contains a single numeric/decimal measurement value
        # - another field contains a single string measurement unit value
        # - each of these measurements should be converted to one additional
        #   unit, with the converted value/unit appended to the appropriate
        #   field
        #
        # Others include:
        #
        # - the default unit strings configured in the transform are those used
        #   in the CollectionSpace measurementUnits vocabulary
        # - standard variants of a unit known by Measured gem are handled
        #   seamlessly (i.e. foot, ft, feet)
        #
        # This transform depends upon the
        #   [Measured gem](https://github.com/Shopify/measured)
        #
        # # Example 1 - Default assumptions
        #
        # Input table:
        #
        # ```
        # | value | unit        |
        # |-------+-------------|
        # | nil   | nil         |
        # | 1.5   | nil         |
        # | 1.5   | inches      |
        # | 1.5   | in.         |
        # | 5     | centimeters |
        # | 2     | feet        |
        # | 2     | meters      |
        # | 2     | pounds      |
        # | 2     | kilograms   |
        # | 2     | ounces      |
        # | 200   | grams       |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Append::ConvertedValueAndUnit,
        #    value: :value,
        #    unit: :unit,
        #    delim: '|',
        #    places: 2
        # ```
        #
        # Results in:
        #
        # ```
        # | value    | unit               |
        # |----------+--------------------|
        # | nil      | nil                |
        # | 1.5      | nil                |
        # | 1.5|3.81 | inches|centimeters |
        # | 1.5|3.81 | in.|centimeters    |
        # | 5|1.97   | centimeters|inches |
        # | 2|0.61   | feet|meters        |
        # | 2|6.56   | meters|feet        |
        # | 2|0.91   | pounds|kilograms   |
        # | 2|4.41   | kilograms|pounds   |
        # | 2|56.7   | ounces|grams       |
        # | 200|7.05 | grams|ounces       |
        # ```
        #
        # # Example 2 - Using a common conversion that isn't configured yet
        #
        # The units that the Measured gem can handle are listed
        #   [here](https://github.com/Shopify/measured#bundled-unit-conversion).
        #   If you want to use one of those, that isn't configured by default in
        #   the transform, you must customize one parameter:
        #
        # - conversions (to indicate that the new unit should be converted to
        #   another, or that another unit should be converted to the new unit
        #
        # You will not need to pass in `conversion_amounts`, as Measured already
        #   knows how to convert these units.
        #
        # Input table:
        #
        # ```
        # | value | unit   |
        # |-------+--------|
        # | 1     | yard   |
        # | 36    | inches |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Append::ConvertedValueAndUnit,
        #    value: :value,
        #    unit: :unit,
        #    delim: '|',
        #    places: 2,
        #    conversions: {'inches'=>'yards', 'yards'=>'feet'}
        # ```
        #
        # Results in:
        #
        # ```
        # | value | unit      |
        # |-------+-----------|
        # | 1|3   | yard|feet |
        # | 36|1  | inches|yd |
        # ```
        #
        # # Example 3 - Fully custom conversions for unknown units
        #
        # Input table:
        #
        # ```
        # | value | unit  |
        # |-------+-------|
        # | 4     | hops  |
        # | 15    | leaps |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Append::ConvertedValueAndUnit,
        #    value: :value,
        #    unit: :unit,
        #    delim: '|',
        #    places: 2,
        #    conversions: {'hops'=>'jumps', 'leaps'=>'hops'},
        #    conversion_amounts: {
        #      leaps: [10, :hops],
        #      hops: [0.25, :jumps]
        #    }
        # ```
        #
        # Results in:
        #
        # ```
        # | value  | unit       |
        # |--------+------------|
        # | 4|1    | hops|jumps |
        # | 15|150 | leaps|hops |
        # ```
        #
        # # Example 4 - overriding default conversions
        #
        # By default, if the existing unit is inches, the conversion will be to
        #   centimeters. The following shows how to convert to feet instead of
        #   centimeters
        #
        # Input table:
        #
        # ```
        # | value | unit    |
        # |-------+---------|
        # | 36    | inches  |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Append::ConvertedValueAndUnit,
        #   value: :value,
        #   unit: :unit,
        #   delim: '|',
        #   places: 2,
        #   conversions: {'inches'=>'feet'}
        # ```
        #
        # Results in:
        #
        # ```
        # | value | unit         |
        # |-------+--------------|
        # | 36|3  | inches|feet  |
        # ```
        #
        # # Example 5 - overriding default converted unit name
        #
        # By default, if the existing unit is converted to centimeters, the
        #   appended unit value will be "centimeters". If you find that
        #   cumbersome and want to output "cm" instead:
        #
        # Input table:
        #
        # ```
        # | value | unit    |
        # |-------+---------|
        # | 36    | inches  |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Append::ConvertedValueAndUnit,
        #   value: :value,
        #   unit: :unit,
        #   delim: '|',
        #   places: 2,
        #   unit_names: {'centimeters'=>'cm'}
        # ```
        #
        # Results in:
        #
        # ```
        # | value    | unit      |
        # |----------+-----------|
        # | 36|91.44 | inches|cm |
        # ```
        class ConvertedValueAndUnit
          # What unit the given unit will be converted to
          #
          # Any custom conversions given are merged into this, so you can
          #   override the defaults
          CONVERSIONS = {
            "inches" => "centimeters",
            "centimeters" => "inches",
            "feet" => "meters",
            "meters" => "feet",
            "kilograms" => "pounds",
            "pounds" => "kilograms",
            "ounces" => "grams",
            "grams" => "ounces"
          }

          # Used internally. You cannot override these
          UNIT_TYPES = {
            "inches" => Measured::Length,
            "centimeters" => Measured::Length,
            "feet" => Measured::Length,
            "meters" => Measured::Length,
            "kilograms" => Measured::Weight,
            "pounds" => Measured::Weight,
            "ounces" => Measured::Weight,
            "grams" => Measured::Weight
          }

          # Convert the value of Measured::Unit.name to unit name expected by
          #   your application
          #
          # By default, these are set up to output unit names as found in
          #   CollectionSpace's measurementunits option list. Override these by
          #   passing in `unit_names` parameter
          UNIT_NAMES = {
            "cm" => "centimeters",
            "ft" => "feet",
            "g" => "grams",
            "in" => "inches",
            "kg" => "kilograms",
            "lb" => "pounds",
            "m" => "meters",
            "oz" => "ounces"
          }

          # @param value [Symbol] name of field containing measurement value
          # @param unit [Symbol] name of field containing measurement unit
          # @param places [Integer] number of decimal places to keep in
          #   converted values
          # @param delim [String] delimiter used when appending value to `value`
          #   and `unit` fields
          # @param conversions [Hash] specify what new unit existing values
          #   should be converted to
          # @param conversion_amounts [Hash] specify conversion rates for new
          #   units
          # @param unit_names [Hash] specify the desired converted-to unit name
          #   to append to field
          # @note See the examples for how to set the `conversions`,
          #   `conversion_amounts`, and `unit_names` parameters
          def initialize(value:, unit:, places:, delim: Kiba::Extend.delim,
            conversions: {}, conversion_amounts: {}, unit_names: {})
            @value = value
            @unit = unit
            @places = places
            @delim = delim
            @types = UNIT_TYPES
            @conversions = CONVERSIONS.merge(conversions)
            type_conversions(conversions)
            @unit_names = UNIT_NAMES.merge(unit_names)
            unless conversion_amounts.empty?
              set_up_custom_conversions(conversion_amounts)
              customize_types(conversion_amounts)
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            value = row.fetch(@value, nil)
            unit = row.fetch(@unit, nil)
            return row if value.blank? || unit.blank?
            return row if multival?(value) || multival?(unit)
            return unknown_unit_type(unit, row) unless known_unit_type?(unit)
            return unknown_conversion(unit, row) unless known_conversion?(unit)
            return not_convertable(unit, row) unless convertable?(unit)

            measured = measured_conversion(value, unit)
            return row if measured == :failure

            converted = measured.convert_to(@conversions[unit])
            conv_value = converted.value
              .to_f
              .round(@places)
              .to_s
              .delete_suffix(".0")
            row[@value] = [value, conv_value].join(@delim)
            row[@unit] = [unit, unit_name(converted.unit)].join(@delim)
            row
          end

          private

          def check_measured_alias_conversions(unit)
            system = measured_unit_system(unit)
            return false unless system

            name = configured_name(system, unit)
            return false unless name

            conversion = @conversions[name]
            return false unless conversion

            @conversions = @conversions.merge({unit => conversion})
            true
          end

          def check_measured_alias_types(unit)
            system = measured_unit_system(unit)
            return false unless system

            @types = @types.merge({unit => system})
            true
          end

          def clean(unit)
            unit.delete_suffix(".").downcase
          end

          def configured_name(system, unit)
            cnames = configured_system_unit_names(system)
            mnames = measured_names(system, unit)
            name = mnames.intersection(cnames)
            return false if name.empty?

            name.first
          end

          def configured_system_unit_names(system)
            types = @types.select { |_unit, type| type == system }.keys
            @conversions.keys.select { |unit| types.any?(unit) }
          end

          def convertable?(unit)
            unit_system = @types[unit]
            true if unit_system.unit_or_alias?(clean(unit)) &&
              unit_system.unit_or_alias?(clean(@conversions[unit]))
          end

          def customize_types(conversion_amounts)
            conversion_amounts.keys.each { |unit|
              @types[unit.to_s] = @converter
            }
          end

          def known_conversion?(unit)
            return true if @conversions.key?(unit)

            check_measured_alias_conversions(unit)
          end

          def known_unit_type?(unit)
            return true if @types.key?(unit)

            check_measured_alias_types(unit)
          end

          def measured_conversion(value, unit)
            @types[unit].new(value, clean(unit))
          rescue
            :failure
          end

          def measured_names(system, unit)
            system.new(1, clean(unit)).unit.names
          end

          def measured_unit_system(unit)
            unit_system = nil
            [Measured::Length, Measured::Weight,
              Measured::Volume].each do |system|
              return system if system.unit_names_with_aliases.any?(clean(unit))
            end
            unit_system
          end

          def multival?(val)
            true if val[@delim]
          end

          def not_convertable(unit, row)
            puts "#{Kiba::Extend.warning_label}: \"#{unit}\" cannot be "\
              "converted to \"#{@conversions[unit]}\". Check your conversions "\
                 "parameter or configure a custom conversion_amounts parameter"
            row
          end

          def set_up_custom_conversions(conversion_amounts)
            units_to_convert = conversion_amounts.keys
            target_units = conversion_amounts.values.map { |arr| arr[1] }
            units_to_convert.each { |unit| @types[unit.to_s] = @converter }

            builder = Measured::UnitSystemBuilder.new

            base_units = target_units - units_to_convert
            base_units.each { |unit| builder.unit(unit.to_sym) }
            units_to_convert.each { |unit|
              builder.unit(unit.to_sym, value: conversion_amounts[unit])
            }

            @converter = Class.new(Measured::Measurable) do
              class << self
                attr_reader :unit_system
              end

              @unit_system = builder.build
            end
          end

          def type_conversions(conversions)
            conversions.keys.each { |ctype| known_unit_type?(ctype) }
          end

          def unit_name(unit)
            name = unit.name
            return name unless @unit_names.key?(name)

            checked = []
            until checked.any?(name) || !@unit_names.key?(name)
              checked << name
              name = @unit_names[name]
            end
            name
          end

          def unknown_conversion(unit, row)
            puts "#{Kiba::Extend.warning_label}: Unknown conversion to "\
              "perform for \"#{unit}\" in \"#{@unit}\" field. Configure "\
              "conversions parameter"
            row
          end

          def unknown_unit_type(unit, row)
            puts "#{Kiba::Extend.warning_label}: Unknown unit \"#{unit}\" in "\
              "\"#{@unit}\" field. You may need to configure a custom unit. "\
                 "See example 3 in transform documentation"
            row
          end
        end
      end
    end
  end
end
