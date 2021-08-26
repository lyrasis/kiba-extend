require_relative 'parser'

module Kiba
  module Extend
    # Reusable, composable patterns for jobs
    #
    # Heretofore, I have been repeating tons of code/logic for setting up a job in migration code:
    #
    # - Defining sources/destinations, @srcrows, @outrows
    # - Changing CSV rows to hashes (initial transforms)
    # - Changing hashes back to CSV rows
    # - Calling postprocessing
    #
    # Most of this never changes, and when it does there is way too much tedious work in a given migration
    #   to make it consistent across all jobs.
    #
    # This is an attempt to dry up calling jobs and make it possible to test them automatically with stubbed-in
    #   enumerable sources/destinations
    #
    # Running `Kiba.parse` to define a job generates a {https://github.com/thbar/kiba/blob/master/lib/kiba/control.rb Kiba::Control}
    #   object, which is a wrapper bundling together: pre_processes, config, sources, transforms, destinations, and
    #   post_processes.
    #
    # As described {https://github.com/thbar/kiba/wiki/Implementing-pre-and-post-processors here}, pre_ and post_
    #   processors get called once per ETL run---either before or after the ETL starts working through the source
    #   rows
    #
    # What Kiba::Extend::Jobs add is the ability to set up reusable initial_transformers and final_transformers.
    #   Basically, job templates where just the meat of the transformations change.
    #
    # `files` is the configuration of destination, source, and lookup files the job will use. It is a Hash, with
    #   the following format:
    #
    #  { source: [registry_key, registry_key], destination: [registry_key], lookup: [registry_key] }
    #
    #  { source: [registry_key, registry_key], destination: [registry_key]}    
    #
    # `source` and `destination` must each have at least one registry key. `lookup` may be omitted, or it may
    #   be included with one or more registry keys
    #    
    # `transformer` is a sequence of data transformations that could theoretically be called with interchangable
    #   input/output settings (i.e. `materials`). In practice, a `recipe` is usually closely tied to particular tables, because
    #   fields are manipulated by name. However, this should support easier automated testing of `recipes`.
    # 
    # @since 2.2.0
    module Jobs
      # Abstract definition of Job and job interface
      #
      # @abstract
      # @return [Kiba::Control]
      class BaseJob
        include Parser
        attr_reader :control, :files, :transformer
        # @param files [Hash]
        # @param transformer [Kiba::Control]
        # @param show [Boolean]
        def initialize(files:, transformer:, show: false)
          @srcrows = 0
          @outrows = 0
          @files = setup_files(files)
          @transformer = transformer
          assemble_control
        end

        def run
          Kiba.run(control)
        end

        #private

        # Must not be the same as any of the core components/methods of {Kiba::Control}, such as
        #  `:sources` or `:transforms`
        def job_instance_variables_deprecate
          { srcrows: 0, outrows: 0 }
        end

        def assemble_control
          @control = parse_job([pre_process, transform, post_process])
          %i[config sources destinations].each do |method_name|
            populate_control(method(method_name))
          end
        end
        
        def assemble_control_deprecate
          set_instance_variables_deprecate
          %i[pre_processes config sources transforms destinations post_processes].each do |method_name|
            puts method_name
            populate_control(method(method_name))
          end
        end

        # @todo raise error if job_instance_variables names conflict with {Kiba::Control} instance variables
        def set_instance_variables
          job_instance_variables.each do |var, val|
            control.instance_variable_set("@#{var}".to_sym, val)
          end
        end
        
        def populate_control(method)
          elements = method.call
          control_method = control.method(method.name)
          target = control_method.call
          if method.name == :config
            target.merge(elements)
          else
            elements.each{ |element| target << element }
          end
        end
        
        def initial_transforms
          Kiba.job_segment do
            transform{ |r| r.to_h }
            transform{ |r| @srcrows += 1; r }
          end
        end

        def final_transforms
          Kiba.job_segment do
            transform{ |r| @outrows += 1; r }
          end
        end

        def pre_process
          Kiba.job_segment do
            pre_process do
              @srcrows = 0
              @outrows = 0
            end
          end
        end

        def config
          Kiba.parse do
          end.config
        end

        def file_config(config)
          {klass: config.klass, args: config.args }
        end
        
        def sources
          @files[:source].map{ |config| file_config(config) }
        end
        
        def destinations
          @files[:destination].map{ |config| file_config(config) }
        end

        def post_process
          Kiba.job_segment do
            post_process do
              puts "#{@outrows} (of #{@srcrows})"
            end
          end
        end
        
        def lookups
        end
        
        def transform
          [initial_transforms, @transformer, final_transforms].flatten
        end

        def setup_files(files)
          tmp = {}
          files.each do |type, arr|
            method = Kiba::Extend.registry.method("as_#{type}")
            tmp[type] = arr.map{ |key| method.call(key) }
          end
          tmp
        end
      end
    end
  end
end
