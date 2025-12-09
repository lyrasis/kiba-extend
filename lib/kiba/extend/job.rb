# frozen_string_literal: true

module Kiba
  module Extend
    # Convenience methods callable on a given job
    module Job
      module_function

      # @param jobkey [Symbol] registry entry for job with namespace
      # @return [nil, Array<Symbol>] headers/fields for given job output
      # @note Only works for CSV and JsonArray destinations. For JsonArray, only
      #   returns the top-level fields of the objects/rows in the output.
      # @since 5.1.0
      def output_fields(jobkey)
        return unless output?(jobkey)

        entry = Kiba::Extend::Registry.entry_for(jobkey)
        path = Pathname.new(entry.path)
        dest = entry.dest_class.new(filename: path)
        unless dest.respond_to?(:fields)
          raise "No output field extraction logic exists for "\
            "#{entry.dest_class}"
        end

        dest.fields
      end

      # @param jobkey [Symbol] registry entry for job with namespace
      # @return [true] if output file already exists when run, or when running
      #   job results in 1 or more rows being written
      # @return [false] if jobkey is not defined, or if job results in 0 rows
      #   when run
      #
      # @since 4.0.0
      def output?(jobkey)
        begin
          reg = Kiba::Extend::Registry.entry_for(jobkey)
        rescue Kiba::Extend::JobNotRegisteredError => err
          puts "#{Kiba::Extend.warning_label}: #{err.message}"
          return false
        end
        return true if File.exist?(reg.path)

        res = Kiba::Extend::Command::Run.job(jobkey)
        return false unless res

        !(res.outrows == 0)
      end
    end
  end
end
