# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      module CsvJob
        # Mixin module containing JobTest behavior for jobs with CSV
        #   destinations
        module Testable
          include JobTestable

          # @return [CSV::Table]
          def get_job_data
            CSV.parse(File.read(path), **Kiba::Extend.csvopts)
          end
        end
      end
    end
  end
end
