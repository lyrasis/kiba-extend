# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Mixin methods for validating a FileRegistryEntry
      module EntryValidatable
        # Allowed registry entry types
        TYPES = %i[file fileset enum lambda]

        private

        def path_required?
          chk = [dest_class, src_class].map do |klass|
            klass.requires_path?
          end
          return false if chk.uniq == [false]

          true
        end

        def validate_creator
          return if supplied
          return if creator.is_a?(Kiba::Extend::Registry::Creator)

          @creator = nil
          @errors[:missing_creator_for_non_supplied_file] = nil
        end

        def validate_lookup
          return unless lookup_on

          supplied ? validate_supplied_lookup : validate_job_lookup
        end

        def validate_job_lookup
          return if dest_class.as_source_class
            .respond_to?(:is_lookupable)

          @errors[:cannot_lookup_from_nonCSV_destination] = nil
        end

        def validate_supplied_lookup
          return if src_class.name.end_with?("CSV")

          @errors[:cannot_lookup_from_nonCSV_supplied_source] = nil
        end

        def validate_path
          if path_required? && !path
            @errors[:missing_path] = nil
            return
          end

          @path = Pathname.new(path) if path
        end

        def validate_type
          return if TYPES.any?(@type)

          @errors[:unknown_type] = @type
        end
      end
    end
  end
end
