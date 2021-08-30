# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Mixin for different behavior for dependency jobs
      module DependencyJob
        extend Kiba::Extend::Jobs::Reporter

        # overrides Runner
        # Don't decorate dependency jobs
        def add_decoration
        end

        # the rest overrides Reporter
        def verbose_start
          puts start_and_def
          puts "  #{desc_and_tags}"
        end

        def normal_start
          puts start_and_def
        end

        # silent for dependency jobs
        def minimal_start
        end

        def verbose_end
          puts "    #{row_report} written to #{job_data.path}"
          puts "    NOTE: #{job_data.message.upcase}" if job_data.message
        end

        # silent for dependency jobs
        def normal_end
        end

        # silent for dependency jobs
        def minimal_end
        end

        def start_label
          '->Starting dependency job'
        end
      end
    end
  end
end
