# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Name
        # rubocop:todo Layout/LineLength
        # Splits an inverted name form into name parts and uses the parts to form a direct-entry name
        # rubocop:enable Layout/LineLength
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
        # rubocop:todo Layout/LineLength
        #  transform Name::ConvertInvertedToDirectForm, source: :iname, target: :direct
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert", :firstname=>"Robert", :middlename=>nil, :lastname=>"Smith", :suffix=>nil, :direct=>"Robert Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert J.", :firstname=>"Robert", :middlename=>"J.", :lastname=>"Smith", :suffix=>nil, :direct=>"Robert J. Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith-Jones, Robert J.", :firstname=>"Robert", :middlename=>"J.", :lastname=>"Smith-Jones", :suffix=>nil, :direct=>"Robert J. Smith-Jones"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert James", :firstname=>"Robert", :middlename=>"James", :lastname=>"Smith", :suffix=>nil, :direct=>"Robert James Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R. James", :firstname=>"R.", :middlename=>"James", :lastname=>"Smith", :suffix=>nil, :direct=>"R. James Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert (Bob)", :firstname=>"Robert", :middlename=>"(Bob)", :lastname=>"Smith", :suffix=>nil, :direct=>"Robert (Bob) Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert James (Bob)", :firstname=>"Robert", :middlename=>"James (Bob)", :lastname=>"Smith", :suffix=>nil, :direct=>"Robert James (Bob) Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R. J.", :firstname=>"R.", :middlename=>"J.", :lastname=>"Smith", :suffix=>nil, :direct=>"R. J. Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R.J.", :firstname=>"R.", :middlename=>"J.", :lastname=>"Smith", :suffix=>nil, :direct=>"R. J. Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R J", :firstname=>"R", :middlename=>"J", :lastname=>"Smith", :suffix=>nil, :direct=>"R J Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, RJ", :firstname=>"R", :middlename=>"J", :lastname=>"Smith", :suffix=>nil, :direct=>"R J Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, RJR", :firstname=>"R", :middlename=>"JR", :lastname=>"Smith", :suffix=>nil, :direct=>"R JR Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, RJRR", :firstname=>"RJRR", :middlename=>nil, :lastname=>"Smith", :suffix=>nil, :direct=>"RJRR Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R.", :firstname=>"R.", :middlename=>nil, :lastname=>"Smith", :suffix=>nil, :direct=>"R. Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil, :direct=>"Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, Robert, Jr.", :firstname=>"Robert", :middlename=>nil, :lastname=>"Smith", :suffix=>"Jr.", :direct=>"Robert Smith, Jr."}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R.J., Sr.", :firstname=>"R.", :middlename=>"J.", :lastname=>"Smith", :suffix=>"Sr.", :direct=>"R. J. Smith, Sr."}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R. J., Sr.", :firstname=>"R.", :middlename=>"J.", :lastname=>"Smith", :suffix=>"Sr.", :direct=>"R. J. Smith, Sr."}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"R.J. Smith & Co.", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil, :direct=>"R.J. Smith & Co."}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, James, Robert & Co.", :firstname=>"James", :middlename=>nil, :lastname=>"Smith", :suffix=>"Robert & Co.", :direct=>"James Smith, Robert & Co."}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"Robert \"Bob\" Smith", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil, :direct=>"Robert \"Bob\" Smith"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>"", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil, :direct=>""}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:iname=>nil, :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil, :direct=>nil}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # {:foo=>"bar", :firstname=>nil, :middlename=>nil, :lastname=>nil, :suffix=>nil, :direct=>nil}
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        #  transform Name::ConvertInvertedToDirectForm, source: :iname, target: :direct, nameparts: %i[f m l s]
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # {:iname=>"Smith, R.J., Sr.", :direct=>"R. J. Smith, Sr.", :f=>"R.", :l=>"Smith", :m=>"J.", :s=>"Sr."}
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        #  transform Name::ConvertInvertedToDirectForm, source: :iname, target: :direct, keep_parts: false
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # {:iname=>"Smith, R.J., Sr.", :direct=>"R. J. Smith, Sr."}
        # ```
        class ConvertInvertedToDirectForm
          # @param source [Symbol] field containing the inverted name to split
          # @param target [Symbol] field in which to write the direct form
          # rubocop:todo Layout/LineLength
          # @param nameparts [Array<Symbol>] field names for the split name parts. Must be provided in order:
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   field for first/given name; field for middle name(s); field for family/sur/last name;
          # rubocop:enable Layout/LineLength
          #   field for suffix/name additions
          # rubocop:todo Layout/LineLength
          # @param keep_parts [Boolean] whether to keep nameparts fields used to generate direct form
          # rubocop:enable Layout/LineLength
          def initialize(source:, target:,
            nameparts: %i[firstname middlename lastname
              suffix], keep_parts: true)
            @source = source
            @target = target
            @nameparts = nameparts
            @firstname = nameparts[0]
            @middlename = nameparts[1]
            @lastname = nameparts[2]
            @suffix = nameparts[3]
            @keep_parts = keep_parts
            @convert_getter = Helpers::FieldValueGetter.new(fields: [firstname,
              middlename, lastname])
            # rubocop:todo Layout/LineLength
            @convertable_getter = Helpers::FieldValueGetter.new(fields: nameparts)
            # rubocop:enable Layout/LineLength
            @splitter = Name::SplitInverted.new(source: source,
              targets: nameparts)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            splitter.process(row)
            if convertable?(row)
              convert(row)
            else
              do_not_convert(row)
            end
            nameparts.each { |field| row.delete(field) } unless keep_parts
            row
          end

          private

          # rubocop:todo Layout/LineLength
          attr_reader :source, :target, :nameparts, :firstname, :middlename, :lastname, :suffix, :keep_parts,
            # rubocop:enable Layout/LineLength
            :convert_getter, :convertable_getter, :splitter

          def convert(row)
            name = convert_getter.call(row)
              .values
              .join(" ")
            sfx = row.fetch(suffix, "")
            row[target] = sfx.blank? ? name : "#{name}, #{sfx}"
          end

          def convertable?(row)
            vals = convertable_getter.call(row)
            true unless vals.empty?
          end

          def do_not_convert(row)
            row[target] = row[source]
          end
        end
      end
    end
  end
end
