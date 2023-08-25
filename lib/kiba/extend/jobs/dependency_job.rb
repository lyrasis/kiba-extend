# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Mixin for different behavior for dependency jobs
      module DependencyJob
        extend Kiba::Extend::Jobs::Reporter

        # overrides Runner
        def add_decoration
          # Don't decorate dependency jobs
        end

        # the rest overrides Reporter
        def verbose_start
          puts start_and_def
          puts "  #{desc_and_tags}"
        end

        def normal_start
          puts start_and_def
        end

        def minimal_start
          # silent for dependency jobs
        end

        def verbose_end
          puts "    #{row_report} written to #{job_data.path}"
          puts "    NOTE: #{job_data.message.upcase}" if job_data.message
        end

        def normal_end
          # silent for dependency jobs
        end

        def minimal_end
          # silent for dependency jobs
        end

        def start_label
          "->Starting dependency job"
        end
      end
    end
  end
end
