# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module DateValue
        # Pads out year or year-month date values to year-month-day
        #   values in ISO 8601 format (yyyy-mm-dd).
        #
        # If a date cannot be converted to a valid ISO 8601 date, the target
        #   field will be nil, and "error" will be written to the warnfield.
        #
        # If a date could be converted, but via an unpredictable means (e.g.
        #   the default Ruby `Date.parse` functionality), then the converted
        #   valid ISO 8601 date is written to target, and "warn" is written to
        #   the warnfield.
        #
        # @note The current iteration of this transform has very limited
        #   date parsing intelligence. We recommend that you set the target
        #   field to a new field, so that you can check the output against the
        #   original values.
        # @note The current iteration interprets a date like "2/4/2001" as
        #   February 4, not April 2. This is not currently configurable.
        # @note The current iteration of this transform will handle 2-digit
        #   years unpredictably
        # @example
        #   # Used in pipeline as:
        #   # transform DateValue::ForceDayPrecision,
        #   #   source: :in,
        #   #   target: :out,
        #   #   month: 2,
        #   #   day: 29,
        #   #   warnfield: :rept
        #   xform = DateValue::ForceDayPrecision.new(
        #     source: :in,
        #     target: :out,
        #     month: 2,
        #     day: 29,
        #     warnfield: :rept
        #   )
        #   input = [
        #     {in: "2000"},
        #     {in: "2001"},
        #     {in: "2000-02"},
        #     {in: "2000/02"},
        #     {in: "02/2000"},
        #     {in: "02/2001"},
        #     {in: "March 2017"},
        #     {in: "2000 Feb"},
        #     {in: "2/4/2017"},
        #     {in: "2/26/2017"},
        #     {in: "2017-02-04"},
        #     {in: "2001-02-29"},
        #     {in: "March 4"},
        #     {in: "March 4, 2015"},
        #     {in: "boom/bop/bam"},
        #     {in: nil},
        #     {in: ""}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {in: "2000", out: "2000-02-29", rept: nil},
        #     {in: "2001", out: nil, rept: "error"},
        #     {in: "2000-02", out: "2000-02-29", rept: nil},
        #     {in: "2000/02", out: "2000-02-29", rept: nil},
        #     {in: "02/2000", out: "2000-02-29", rept: nil},
        #     {in: "02/2001", out: nil, rept: "error"},
        #     {in: "March 2017", out: "2017-03-29", rept: nil},
        #     {in: "2000 Feb", out: "2000-02-29", rept: nil},
        #     {in: "2/4/2017", out: "2017-02-04", rept: nil},
        #     {in: "2/26/2017", out: "2017-02-26", rept: nil},
        #     {in: "2017-02-04", out: "2017-02-04", rept: nil},
        #     {in: "2001-02-29", out: nil, rept: "error"},
        #     {in: "March 4", out: "2026-03-04", rept: "warn"},
        #     {in: "March 4, 2015", out: "2015-03-04", rept: "warn"},
        #     {in: "boom/bop/bam", out: nil, rept: "error"},
        #     {in: nil, out: nil, rept: nil},
        #     {in: "", out: nil, rept: nil}
        #   ]
        #   expect(result).to eq(expected)
        #   Kiba::Extend::ProjectConfig.reset_config
        class ForceDayPrecision
          # @param source [Symbol] field containing non-day-precise date values
          # @param target [Symbol] field in which to write day-precise date
          #   values
          # @param warnfield [Symbol] field in which to write error and warning
          #   flags
          # @month [Integer] Default month to provide
          # @day [Integer] Default day to provide. **This must be a valid day
          #   for any month in a year-month source value.** For instance, you
          #   cannot set this to 31, and succssfully pad 2002-02.
          def initialize(source:, target:, warnfield: :date_warning,
            month: 1, day: 1)
            @source = source
            @target = target
            @warnfield = warnfield
            @month = month
            @day = day
          end

          def process(row)
            [target, warnfield].each { |f| row[f] = nil }
            val = row[source]
            return row if val.blank?

            write_target_and_warnings(get_result(val), row)

            row
          end

          private

          attr_reader :source, :target, :warnfield, :month, :day

          def get_result(val)
            if val.match?(/^\d{4}$/)
              year_only(val)
            elsif iso8601?(val)
              validated_date(val)
            elsif three_part?(val) &&
                all_numeric?(val) &&
                four_digit_year?(val)
              ymd_numeric_date(val)
            elsif two_part?(val) &&
                all_numeric?(val) &&
                four_digit_year?(val)
              month_year(val)
            elsif two_part?(val) &&
                four_digit_year?(val) &&
                month_word?(val)
              month_word_year(val)
            else
              take_your_chances(val)
            end
          end

          def write_target_and_warnings(result, row)
            if result == :error
              row[warnfield] = result.to_s
              row[target] = nil
            elsif result.is_a?(Array)
              row[warnfield] = result[0].to_s
              row[target] = result[1]
            else
              row[target] = result
            end
          end

          def year_only(val)
            Date.new(val.to_i, month, day).iso8601
          rescue
            :error
          end

          def three_part?(val) = parts(val).length == 3

          def two_part?(val) = parts(val).length == 2

          def all_numeric?(val) = parts(val).all? { |e| e.match?(/^\d+$/) }

          def four_digit_year?(val)
            matches = parts(val).select { |e| e.match?(/^\d{4}$/) }
            matches.length == 1
          end

          def month_word?(val)
            months = (Date::MONTHNAMES + Date::ABBR_MONTHNAMES).compact
            matches = parts(val).select { |e| months.include?(e) }
            matches.length == 1
          end

          def four_digit_year(val) = parts(val).find { |e| e.match?(/^\d{4}$/) }

          def iso8601?(val) = val.match?(/^\d{4}-\d{2}-\d{2}$/)

          def ymd_numeric_date(val)
            parts = parts(val)
            year = four_digit_year(val)
            parts.delete(year)
            Date.new(year.to_i, parts[0].to_i, parts[1].to_i).iso8601
          rescue
            :error
          end

          def month_year(val)
            parts = parts(val)
            year = four_digit_year(val)
            parts.delete(year)
            Date.new(year.to_i, parts[0].to_i, day).iso8601
          rescue
            :error
          end

          def month_word_year(val)
            parsed = Date.parse(val)
            Date.new(parsed.year, parsed.month, day).iso8601
          rescue
            :error
          end

          def take_your_chances(val)
            date = Date.parse(val)
            [:warn, date.iso8601]
          rescue
            :error
          end

          def validated_date(val)
            Date.parse(val).iso8601
          rescue
            :error
          end

          def parts(val) = val.split(/-| |\//)
        end
      end
    end
  end
end
