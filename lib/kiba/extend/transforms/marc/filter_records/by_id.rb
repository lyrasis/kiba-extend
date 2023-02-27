# frozen_string_literal: true

require 'marc'

module Kiba
  module Extend
    module Transforms
      module Marc
        module FilterRecords
          # Select or reject MARC records based on whether id extracted from
          #   record matches any values in given id_values
          #
          # @example Keeping matches
          #   ids = ['008000103-3', '008000204-8', '008000307-9']
          #   xform = Marc::FilterRecords::ById.new(
          #     id_values: ids,
          #     action: :keep
          #   )
          #   results = []
          #   MARC::Reader.new(marc_file).each{ |rec|
          #     xform.process(rec){ |result| results << result }
          #   }
          #   expect(results.length).to eq(3)
          # @example Rejecting matches
          #   ids = ['008000103-3', '008000204-8', '008000307-9']
          #   xform = Marc::FilterRecords::ById.new(
          #     id_values: ids,
          #     action: :reject
          #   )
          #   results = []
          #   MARC::Reader.new(marc_file).each{ |rec|
          #     xform.process(rec){ |result| results << result }
          #   }
          #   expect(results.length).to eq(7)
          # @example Changing id extraction settings
          #   ids = ['(OCoLC)01484180', 'ocm40873877']
          #   xform = Marc::FilterRecords::ById.new(
          #     id_values: ids,
          #     action: :keep,
          #     id_tag: '035',
          #     id_subfield: 'a'
          #   )
          #   results = []
          #   MARC::Reader.new(marc_file).each{ |rec|
          #     xform.process(rec){ |result| results << result }
          #   }
          #   expect(results.length).to eq(2)
          # @example With `id_values` Proc
          #   xform = Marc::FilterRecords::ById.new(
          #     id_values: ->{
          #       ['8000103-3', '8000204-8', '8000307-9'].map{ |val|
          #         "00#{val}"
          #       }
          #     },
          #     action: :keep
          #   )
          #   results = []
          #   MARC::Reader.new(marc_file).each{ |rec|
          #     xform.process(rec){ |result| results << result }
          #   }
          #   expect(results.length).to eq(3)
          class ById
            include ActionArgumentable

            # @param id_values [Array, Proc] against which IDs extracted from
            #   source records will be matched
            # @param action [:keep, :reject] taken if source record ID matches
            #   a value in `id_values`
            # @param id_tag See {Kiba::Extend::Marc.id_tag}
            # @param id_field_selector See
            #   {Kiba::Extend::Marc.id_field_selector}
            # @param id_subfield See {Kiba::Extend::Marc.id_subfield}
            # @param id_subfield_selector See
            #   {Kiba::Extend::Marc.id_subfield_selector}
            # @param id_value_formatter See
            #   {Kiba::Extend::Marc.id_value_formatter}
            def initialize(
              id_values:, action:,
              id_tag: nil,
              id_field_selector: nil,
              id_subfield: nil,
              id_subfield_selector: nil,
              id_value_formatter: nil
            )
              @ids = id_values.is_a?(Array) ? id_values : id_values.call
              validate_action_argument(action)
              @action = action

              settings = {
                id_tag: id_tag,
                id_field_selector: id_field_selector,
                id_subfield: id_subfield,
                id_subfield_selector: id_subfield_selector,
                id_value_formatter: id_value_formatter
              }.compact
              @idextractor = Kiba::Extend::Utils::MarcIdExtractor.new(**settings)
            end

            # @param record [MARC::Record] to check for ID match
            # @yield record MARC record, if it matches criteria
            # @yieldparam [MARC::Record] yielded MARC record, if any
            def process(record)
              case action
              when :keep
                yield record if match?(record)
              when :reject
                yield record unless match?(record)
              end
              nil
            end

            private

            attr_reader :ids, :action, :existing_config, :idextractor

            def match?(record)
              ids.any?(idextractor.call(record))
            end
          end
        end
      end
    end
  end
end
