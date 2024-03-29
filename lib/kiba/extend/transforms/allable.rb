# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Mixin module providing `finalize_fields` method for transforms that
      #   accept `fields: :all`.
      #
      # ## Usage
      #
      # Any transform classes mixing in this module must have `fields` as an
      #   attr_reader
      #
      # Set the `fields` instance variable from user input as follows:
      #
      # ~~~
      #  @fields = [fields].flatten
      # ~~~
      #
      # Add the following line as the first thing in the `process` method:
      #
      # ~~~
      # finalize_fields(row) unless fields_set
      # ~~~
      #
      # @since 2.8.0
      module Allable
        ::Allable = Kiba::Extend::Transforms::Allable

        module_function

        def all_fields(row)
          @fields = row.keys
          @fields_set = true
        end
        private_class_method :all_fields

        def all_is_field
          @fields_set = true
        end
        private_class_method :all_is_field

        def fields_set
          @fields_set
        end
        private_class_method :fields_set

        def finalize_fields(row)
          if fields == [:all]
            row.key?(:all) ? all_is_field : all_fields(row)
          else
            @fields_set = true
          end
        end
        private_class_method :finalize_fields
      end
    end
  end
end
