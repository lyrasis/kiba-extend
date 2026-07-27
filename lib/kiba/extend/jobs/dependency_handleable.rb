# frozen_string_literal: true

module Kiba
  module Extend
    module Jobs
      # The methods that need to be mixed in to a Job to handle dependencies
      module DependencyHandleable
        # Replace file key names with registered_source/lookup/destination
        #   objects dynamically
        def setup_files(files)
          files.map { |type, arr| [type, setup_files_for(type, arr)] }
            .to_h
        end

        def setup_files_for(type, arr)
          arr.map { |key| setup_file_for(type, key) }
        end

        def setup_file_for(type, key)
          return setup_source_for(key) if type == :source

          prep_file(
            Kiba::Extend.registry.method(:"as_#{type}"), key, destination_key
          )
        end

        def setup_source_for(key)
          entry = Kiba::Extend.registry.resolve(key)
          return entry if entry.dynamic_source

          meth = Kiba::Extend.registry.method(:as_source)
          prep_file(meth, key, destination_key)
        end

        def prep_file(meth, key, for_job)
          meth.call(key, for_job)
        rescue Kiba::Extend::ErrMod => err
          if err.respond_to?(:formatted)
            puts err.formatted
          else
            puts "JOB FAILED: TRANSFORM ERROR IN: #{err.calling_job}"
            err.info
          end
          exit
        end

        # @param type [:source, :lookup]
        def handle_requirements(type)
          deps = files[type]
          return unless deps

          deps.flatten
            .compact
            .each do |registered|
              req = registered.required
              next unless req

              req.call
            end
          check_requirements(type)
        rescue Kiba::Extend::MissingDependencyError => err
          puts "JOB FAILED: DEPENDENCY ERROR IN: #{err.calling_job}"
          err.info
          exit
        rescue => err
          puts "JOB FAILED: Error handling #{type} file dependency for "\
            "#{destination_key}: #{err.message}"
        end

        # @param type [:source, :lookup]
        def check_requirements(type)
          files[type].flatten.compact.each do |data|
            next unless data.path
            next if File.exist?(data.path)

            fail Kiba::Extend::MissingDependencyError.new(data.key, data.path)
          end
        end

        def destinations
          @files[:destination].map { |config| file_config(config) }
            .map { |src| "destination #{src[:klass]}, **#{src[:args]}" }
            .join("\n")
        end

        def sources
          @files[:source].map { |config| file_config(config) }
            .map { |src| "source #{src[:klass]}, **#{src[:args]}" }
            .join("\n")
        end

        def file_config(config)
          {klass: config.klass, args: config.args}
        end
      end
    end
  end
end
