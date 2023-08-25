# frozen_string_literal: true

require_relative "reporter"

module Kiba
  module Extend
    module Jobs
      # The methods that need to be mixed in to a Job to make it run
      #
      # These methods are intended to be agnostic of the job segment/step logic,
      #   which is why they are separated out into a module
      module Runner
        include Reporter
        # rubocop:todo Layout/LineLength
        # Error raised if dependency file is still missing after we tried to run dependencies
        # rubocop:enable Layout/LineLength
        class MissingDependencyError < Kiba::Extend::Error
          # rubocop:todo Layout/LineLength
          # @param filekey [Symbol] key for which a file path was not found in {Kiba::Extend::FileRegistry}
          # rubocop:enable Layout/LineLength
          def initialize(filekey, path)
            msg = "Cannot locate dependent file for #{filekey} at #{path}"
            super(msg)
          end
        end

        def add_decoration
          show_me_decoration
          tell_me_decoration
        end

        # rubocop:todo Layout/LineLength
        # Add lookup tables to the context as methods memoized to instance variables
        # rubocop:enable Layout/LineLength
        def add_lookup(config)
          key_as_iv = "@#{config.key}".to_sym

          context.define_singleton_method(config.key) {
            if instance_variable_defined?(key_as_iv)
              instance_variable_get(key_as_iv)
            else
              instance_variable_set(
                key_as_iv,
                Lookup.csv_to_hash(**config.args.compact)
              )
            end
          }
        end

        # This stuff does not get handled by parsing source code
        def add_config
          return if config.empty?

          control.config.merge(config)
        end

        def add_destinations
          context.instance_eval(destinations)
        end

        def add_sources
          context.instance_eval(sources)
        end

        def assemble_control
          lookups_to_memoized_methods if @files[:lookup]
          parse_job_segments
          add_config
          add_sources
          add_destinations
          add_decoration
          control
        end

        def check_requirements
          [@files[:source], @files[:lookup]].compact.flatten.each do |data|
            next unless data.path
            next if File.exist?(data.path)

            fail MissingDependencyError.new(data.key, data.path)
          end
        end

        def destinations
          @files[:destination].map { |config| file_config(config) }
            .map { |src| "destination #{src[:klass]}, **#{src[:args]}" }
            .join("\n")
        end

        def file_config(config)
          {klass: config.klass, args: config.args}
        end

        def handle_requirements
          [@files[:source], @files[:lookup]].compact
            .flatten
            .compact
            .each do |registered|
              next unless registered.required

              registered.required.call
            end

          check_requirements
        rescue MissingDependencyError => err
          puts "JOB FAILED: DEPENDENCY ERROR IN: #{err.calling_job}"
          err.info
          exit
        end

        def lookups_to_memoized_methods
          @files[:lookup].each do |config|
            add_lookup(config)
          end
        end

        # The parts that get generated by parsing of Kiba code blocks
        def parse_job_segments
          parse_job(control, context, [pre_process, transform, post_process])
        end

        def show_me_decoration
          return unless Kiba::Extend.job_show_me

          extend ShowMeJob
          decorate
        end

        def sources
          @files[:source].map { |config| file_config(config) }
            .map { |src| "source #{src[:klass]}, **#{src[:args]}" }
            .join("\n")
        end

        def tell_me_decoration
          return unless Kiba::Extend.job_tell_me

          extend TellMeJob
          decorate
        end

        def transform
          [initial_transforms, @transformer, final_transforms].flatten
        end
      end
    end
  end
end
