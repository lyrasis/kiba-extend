# frozen_string_literal: true

module Kiba
  module Extend
    # Convenience methods callable on a given job
    module Job
      module_function

      # @param jobkey [Symbol] registry entry for job with namespace
      # @return [true] if output file already exists when run, or when running
      #   job results in 1 or more rows being written
      # @return [false] if jobkey is not defined, or if job results in 0 rows
      #   when run
      #
      # @since 4.0.0
      def output?(jobkey)
        begin
          reg = Kiba::Extend.registry.resolve(jobkey)
        rescue Dry::Container::KeyError
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
