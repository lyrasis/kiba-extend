# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # Mixin methods for reporting
      module Reporter
        def report_run_start
          @start = Time.now unless @dependency
          case Kiba::Extend.job_verbosity
          when :verbose
            verbose_start
            nil
          when :minimal
            minimal_start
            nil
          else
            normal_start
          end
        end

        def report_run_end
          @duration = Time.now - @start unless @dependency
          case Kiba::Extend.job_verbosity
          when :verbose
            verbose_end
            nil
          when :minimal
            minimal_end
            nil
          else
            normal_end
          end
        end

        def verbose_start
          puts "\n-=-=-=-=-=-=-=-=-=-=-=-"
          puts start_and_def
          puts desc_and_tags
          puts ""
          put_file_details
        end

        def normal_start
          puts "\n-=-=-=-=-=-=-=-=-=-=-=-"
          puts start_and_def
          puts desc_and_tags
          puts ""
        end

        def minimal_start
          puts "\n-=-=-=-=-=-=-=-=-=-=-=-"
          puts start_and_def
        end

        def verbose_end
          puts "\n#{job_data.key} complete (#{get_duration})"
          puts "#{row_report} written to #{job_data.path}"
          puts "NOTE: #{job_data.message.upcase}" if job_data.message
          puts "-=-=-=-=-=-=-=-=-=-=-=-"
          puts ""
        end

        def normal_end
          puts "\n#{row_report} written to #{job_data.path} in #{get_duration}"
          puts "NOTE: #{job_data.message.upcase}" if job_data.message
          puts "-=-=-=-=-=-=-=-=-=-=-=-"
          puts ""
        end

        # silent
        def minimal_end
          puts row_report
          puts "-=-=-=-=-=-=-=-=-=-=-=-"
          puts ""
        end

        def start_label
          "->Starting dependency job"
        end

        def desc_and_tags
          parts = [job_data.desc, tags].compact
          return if parts.empty?

          parts.join(" -- ")
        end

        def put_file_details
          puts "SOURCES"
          @files[:source].each { |src| puts "source #{src.klass} #{src.args}" }
          puts "DESTINATIONS"
          @files[:destination].each { |dest|
            puts "destination #{dest.klass} #{dest.args}"
          }
          if @files[:lookup]
            puts "LOOKUPS"
            @files[:lookup].each { |lkup| puts "lookup #{lkup.args}" }
          end
          puts ""
        end

        def row_report
          "#{outrows} of #{srcrows}"
        end

        def start_label
          "Starting job"
        end

        def start_and_def
          "#{start_label}: #{job_data.key} -- defined in: #{job_data.creator}"
        end

        def tags
          tags = job_data.tags
          return unless tags

          "tags: [#{tags.join(", ")}]"
        end

        def get_duration
          return "" if @dependency

          minutes = (@duration / 60).floor
          seconds = (@duration - (minutes * 60)).ceil
          "#{minutes}m #{seconds}s"
        rescue
          ""
        end
      end
    end
  end
end
