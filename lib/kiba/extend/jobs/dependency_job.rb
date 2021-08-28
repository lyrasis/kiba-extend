module Kiba
  module Extend
    module Jobs
      # Mixin for different behavior for dependency jobs
      module DependencyJob
        extend Kiba::Extend::Jobs::Reporter

        # Don't decorate dependency jobs
        def add_decoration
        end
        
        def report_run_start
          case Kiba::Extend.job.verbosity
          when :verbose
            verbose_start
            return
          when :minimal
            minimal_start
            return
          end

          puts start_and_def
        end

        def report_run_end
          case Kiba::Extend.job.verbosity
          when :verbose
            verbose_end
            return
          when :minimal
            minimal_end
            return
          end
        end

        def verbose_start
          puts start_and_def
          puts "  #{desc_and_tags}"
        end

        # minimal = silent for dependency jobs
        def minimal_start
        end

        def verbose_end
        end

        # minimal = silent for dependency jobs        
        def minimal_end
        end

        def start_label
          '->Starting dependency job'
        end
        
        
      end
    end
  end
end
