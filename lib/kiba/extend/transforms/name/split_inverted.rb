# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Name
        # Splits an inverted name form into name parts.
        #
        # rubocop:todo Layout/LineLength
        # @note Makes many egregiously oversimplified Western assumptions. Do not trust it to split all names
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   properly in all cases. Handles only the most common English language name patterns.
        # rubocop:enable Layout/LineLength
        #
        # # Examples
        #
        # rubocop:todo Layout/LineLength
        # In these examples, you can see the inverted name in the `:iname` field of each row.
        # rubocop:enable Layout/LineLength
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Name::SplitInverted, source: :iname
        # ```
        #
        # Results in:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert", :firstname=>"Robert", :middlename=>nil, :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert J.", :firstname=>"Robert", :middlename=>"J.", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith-Jones, Robert J.", :firstname=>"Robert", :middlename=>"J.", :lastname=>"Smith-Jones", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert James", :firstname=>"Robert", :middlename=>"James", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R. James", :firstname=>"R.", :middlename=>"James", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert (Bob)", :firstname=>"Robert", :middlename=>"(Bob)", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert James (Bob)", :firstname=>"Robert", :middlename=>"James (Bob)", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R. J.", :firstname=>"R.", :middlename=>"J.", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R.J.", :firstname=>"R.", :middlename=>"J.", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R J", :firstname=>"R", :middlename=>"J", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, RJ", :firstname=>"R", :middlename=>"J", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, RJR", :firstname=>"R", :middlename=>"JR", :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, RJRR", :firstname=>"RJRR", :middlename=>nil, :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R.", :firstname=>"R.", :middlename=>nil, :lastname=>"Smith", :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert, Jr.", :firstname=>"Robert", :middlename=>nil, :lastname=>"Smith", :suffix=>"Jr."}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R.J., Sr.", :firstname=>"R.", :middlename=>"J.", :lastname=>"Smith", :suffix=>"Sr."}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R. J., Sr.", :firstname=>"R.", :middlename=>"J.", :lastname=>"Smith", :suffix=>"Sr."}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"R.J. Smith & Co.", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, James, Robert & Co.", :firstname=>"James", :middlename=>nil, :lastname=>"Smith", :suffix=>"Robert & Co."}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Robert \"Bob\" Smith", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>nil, :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:foo=>"bar", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Name::SplitInverted, source: :iname, targets: %i[f m l s]
        # ```
        #
        # Results in:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R.J., Sr.", :f=>"R.", :l=>"Smith", :m=>"J.", :s=>"Sr."}
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Name::SplitInverted, source: :iname, fallback: :lastname
        # ```
        #
        # Results in:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith", :firstname=>nil, :lastname=>"Smith", :middlename=>nil, :suffix=>nil}
        # rubocop:enable Layout/LineLength
        # ```
        class SplitInverted
          # @param source [Symbol] field containing the inverted name to split
          # rubocop:todo Layout/LineLength
          # @param targets [Array<Symbol>] field names for the split name parts. Must be provided in order:
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   field for first/given name; field for middle name(s); field for family/sur/last name;
          # rubocop:enable Layout/LineLength
          #   field for suffix/name additions
          # rubocop:todo Layout/LineLength
          # @param fallback [Symbol] :all_nil will set all targets to nil. Given the name of one of the targets,
          # rubocop:enable Layout/LineLength
          #   will copy the source value into that field
          def initialize(source:,
            targets: %i[firstname middlename lastname
              suffix], fallback: :all_nil)
            @source = source
            @targets = targets
            @firstname = targets[0]
            @middlename = targets[1]
            @lastname = targets[2]
            @suffix = targets[3]
            @fallback = fallback
            unless fallback == :all_nil || targets.any?(fallback)
              raise ArgumentError,
                "fallback must equal :all_nil or one of the target field names"
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            create_nil_fields(row)
            inverted = row.fetch(source, "")
            if splittable?(inverted)
              split(inverted, row)
            else
              do_not_split(inverted, row)
            end
          end

          private

          attr_reader :source, :targets, :firstname, :middlename, :lastname,
            :suffix, :fallback

          def create_nil_fields(row)
            targets.each { |field| row[field] = nil }
          end

          def do_not_split(val, row)
            return row if fallback == :all_nil

            row[fallback] = val
            row
          end

          def first_and_middle(val, row)
            unspaced_initials?(val) ? smooshed_initials(val,
              row) : space_split(val, row)
          end

          def unspaced_initials?(val)
            patterns = [
              /^([a-z]\.){2,}$/i,
              /^[A-Z]{2,3}$/
            ]
            patterns.any? { |pattern| pattern.match?(val) }
          end

          def smooshed_initials(val, row)
            sval = val.partition(/.\./)
            if sval.first.empty?
              row[firstname] = sval[1]
              row[middlename] = sval[2]
            else
              row[firstname] = sval[0][0]
              row[middlename] = sval[0][1..]
            end
          end

          def space_split(val, row)
            sval = val.split(" ")
            row[firstname] = sval.shift
            row[middlename] = sval.join(" ") unless sval.empty?
          end

          def split(val, row)
            sval = val.split(",").map(&:strip)
            row[lastname] = sval.shift
            first_and_middle(sval.shift, row) unless sval.empty?

            row[suffix] = sval.join(", ") unless sval.empty?
            row
          end

          def splittable?(val)
            return false unless val

            true if val[","]
          end
        end
      end
    end
  end
end
