module Kiba
  module Extend
    module Jobs
      # Mixin methods for reporting
      module Reporter
        def report_run_start
          case Kiba::Extend.job.verbosity
          when :verbose
            verbose_start
            return
          when :minimal
            minimal_start
            return
          end

          puts "\n-=-=-=-=-=-=-=-=-=-=-=-"
          puts start_and_def
          puts desc_and_tags
          puts ''
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

          puts "written to #{job_data.path}"
          puts "NOTE: #{job_data.message.upcase}" if job_data.message
          puts ''
        end

        def verbose_start
          puts "\n-=-=-=-=-=-=-=-=-=-=-=-"
          puts start_and_def
          puts desc_and_tags
          puts ''
          put_file_details
        end
        
        def minimal_start
          puts start_and_def
        end

        def verbose_end
        end

        # minimal = silent for dependency jobs        
        def minimal_end
        end

        def start_label
          '->Starting dependency job'
        end

        def creator_method_to_s
          job_data.creator.to_s
            .delete_prefix('#<Method: ')
            .sub(/\(\) .*$/, '')          
        end
        
        def desc_and_tags
          parts = [job_data.desc, tags].compact
          return if parts.empty?

          parts.join(' -- ')
        end

        def put_file_details
          puts "SOURCES"
          @files[:source].each{ |src| puts "source #{src.klass} #{src.args}" }
          puts 'DESTINATIONS'
          @files[:destination].each{ |dest| puts "destination #{dest.klass} #{dest.args}" }
          if @files[:lookup]
            puts 'LOOKUPS'
            @files[:lookup].each{ |lkup| puts "lookup #{lkup.args}" }
          end
          puts ''
        end
        
        def start_label
          'Starting job'
        end

        def start_and_def
          "#{start_label}: #{job_data.key} -- defined in: #{creator_method_to_s}"
        end

        def tags
          tags = job_data.tags
          return unless tags

          "tags: [#{tags.join(', ')}]"
        end
        
      end
    end
  end
end
