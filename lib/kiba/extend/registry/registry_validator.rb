# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Utility class to report on the validity of the FileRegistry.
      class RegistryValidator
        # Prints to STDOUT a report of errors and warnings to inform needed development in project applications
        def report
          puts ''
          report_validity
          report_warnings
        end

        # Check validity of the registry as a whole
        # @return [TrueClass] if all Entries are valid
        # @return [FalseClass] is any Entries are invalid
        def valid?
          return true if invalid.empty?

          false
        end

        # Whether any entries have warnings
        # @return [TrueClass] if any Entries have warnings
        # @return [FalseClass] is no Entries have warnings
        def warnings?
          return false if warnings.empty?

          true
        end

        private

        def errs_to_str(errs)
          errs.map { |key, val| "#{key} #{val}" }.join('; ')
        end

        def invalid
          Kiba::Extend.registry.entries.reject { |entry| entry.valid? }
        end

        def report_invalid
          puts "Error count: #{invalid.length}"
          invalid.each do |entry|
            puts "  #{entry.key}: #{errs_to_str(entry.errors)}"
          end
        end

        def report_validity
          if valid?
            puts 'All file registry entries are valid!'
            return
          end

          report_invalid
        end

        def report_warnings
          unless warnings?
            puts 'No warnings!'
            return
          end

          puts "Warning count: #{warnings.length}"
          warnings.each do |entry|
            puts "  #{entry.key}: #{entry.warnings.join('; ')}"
          end
        end

        def warnings
          Kiba::Extend.registry.entries.reject { |entry| entry.warnings.empty? }
        end
      end
    end
  end
end
