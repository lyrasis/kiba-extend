# frozen_string_literal: true

require 'measured'

module Kiba
  module Extend
    module Transforms
      module Append
        # Adds the given field(s) to the row with nil value if they do not already exist in row
        #
        # # Examples
        #
        # Input table is not shown separately. It is just `name` column of the results tables shown below. The blank
        #   value in name indicates an empty Ruby String object. The nil indicates a Ruby NilValue object.
        #
        # ## Example 1
        # No placeholder value is given, so "NULL" is treated as a string value. `count_empty` defaults to false, so
        #   empty values are not counted.
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Count::FieldValues, field: :name, target: :ct, delim: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | name                 | ct |
        # |----------------------+----|
        # | Weddy                | 1  |
        # | NULL                 | 1  |
        # |                      | 0  |
        # | nil                  | 0  |
        # | Earlybird;Divebomber | 2  |
        # | ;Niblet              | 1  |
        # | Hunter;              | 1  |
        # | NULL;Earhart         | 2  |
        # | ;                    | 0  |
        # | NULL;NULL            | 2  |
        # ```
        #
        class ConvertedValueAndUnit
          # What unit the given unit will be converted to
          #
          # Any custom conversions given are merged into this, so you can override the defaults
          Conversions = {
            'inches' => 'centimeters',
            'centimeters' => 'inches',
            'feet' => 'meters',
            'meters' => 'feet',
            'kilograms' => 'pounds',
            'pounds' => 'kilograms',
            'ounces' => 'grams',
            'grams' => 'ounces'
          }

          UnitTypes = {
            'inches' => Measured::Length,
            'centimeters' => Measured::Length,
            'feet' => Measured::Length,
            'meters' => Measured::Length,
            'kilograms' => Measured::Weight,
            'pounds' => Measured::Weight,
            'ounces' => Measured::Weight,
            'grams' => Measured::Weight
          }

          # Convert the value of Measured::Unit.name to unit name expected by your application
          #
          # By default, these are set up to output unit names as found in CollectionSpace's measurementunits option list.
          #   Override these by passing in `unit_names` parameter
          UnitNames = {
            'cm' => 'centimeters',
            'g' => 'grams',
            'kg' => 'kilograms',
            'm' => 'meters'
          }
          def initialize(value:, unit:, places:, delim: Kiba::Extend.delim, conversions: {}, types: {},
                         conversion_amounts: {}, unit_names: {})
            @value = value
            @unit = unit
            @places = places
            @delim = delim
            @conversions = Conversions.merge(conversions)
            @types = UnitTypes.merge(types)
            @unit_names = UnitNames.merge(unit_names)
            unless conversion_amounts.empty?
              set_up_custom_conversions(conversion_amounts) 
              customize_types(conversion_amounts)
            end
          end

          # @private
          def process(row)
            value = row.fetch(@value, nil)
            unit = row.fetch(@unit, nil)
            return row if value.blank? || unit.blank?

            return unknown_unit_type(unit, row) unless known_unit_type?(unit)
            return unknown_conversion(unit, row) unless known_conversion?(unit)
            return not_convertable(unit, row) unless convertable?(unit)

            measured = @types[unit].new(value, unit)
            converted = measured.convert_to(@conversions[unit])
            row[@value] = [value, converted.value.to_f.round(@places)].join(@delim)
            row[@unit] = [unit, unit_name(converted.unit)].join(@delim)
            row
          end

          private

          def convertable?(unit)
            unit_system = @types[unit]
            true if unit_system.unit_or_alias?(unit) && unit_system.unit_or_alias?(@conversions[unit])
          end

          def customize_types(conversion_amounts)
            conversion_amounts.keys.each{ |unit| @types[unit.to_s] = @converter }
          end
          
          def known_conversion?(unit)
            @conversions.key?(unit)
          end

          def known_unit_type?(unit)
            @types.key?(unit)
          end

          def not_convertable(unit, row)
            puts %Q[#{Kiba::Extend.warning_label}: No known conversion method for "#{unit}" to "#{@conversions[unit]}" in "#{@unit}" field. Configure conversion_amounts parameter]
            row
          end

          def set_up_custom_conversions(conversion_amounts)
            units_to_convert = conversion_amounts.keys
            target_units = conversion_amounts.values.map{ |arr| arr[1] }
            units_to_convert.each{ |unit| @types[unit.to_s] = @converter }

            builder = Measured::UnitSystemBuilder.new

            target_units.each{ |unit| builder.unit(unit.to_sym) }
            units_to_convert.each{ |unit| builder.unit(unit.to_sym, value: conversion_amounts[unit]) }

            
            @converter =  Class.new(Measured::Measurable) do
              class << self
                attr_reader :unit_system
              end

              @unit_system = builder.build
            end
          end

          def unit_name(unit)
            name = unit.name
            return @unit_names[name] if @unit_names.key?(name)

            name
          end
          
          def unknown_conversion(unit, row)
            puts %Q[#{Kiba::Extend.warning_label}: Unknown conversion to perform for "#{unit}" in "#{@unit}" field. Configure conversions parameter]
            row
          end
          
          def unknown_unit_type(unit, row)
            puts %Q[#{Kiba::Extend.warning_label}: Unknown unit type "#{unit}" in "#{@unit}" field. Configure types parameter]
            row
          end

        end
      end
    end
  end
end
