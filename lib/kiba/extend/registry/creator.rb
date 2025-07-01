# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Registry
      # Bundles up the logic/options of different ways of validating and calling registry entry creators
      class Creator
        attr_reader :mod, :meth, :args

        def initialize(spec)
          @spec = spec.is_a?(Proc) ? spec.call : spec
          if Kiba::Extend.job_verbosity == :verbose
            puts "Initializing Creator class for #{@spec}"
          end
          @mod = nil
          @meth = nil
          @args = nil
          set_vars
        end

        def call
          if args
            mod.send(meth, **args)
          else
            mod.send(meth)
          end
        end

        def to_s
          mod_meth = "#{mod}.#{meth}"
          return mod_meth unless args

          arg_str = args.map { |key, val| "#{key}: #{val}" }
            .join(", ")
          "#{mod_meth}(#{arg_str})"
        end

        private

        attr_reader :spec

        def args_type_ok?
          spec[:args].is_a?(Hash)
        end

        def callee_ok?
          callee = spec[:callee]
          callee.is_a?(Method) || callee.is_a?(Module)
        end

        def set_vars
          case spec.class.to_s
          when "Method"
            setup_method_spec
          when "Module"
            setup_module_spec
          when "Hash"
            setup_hash_spec
          else
            raise TypeError.new(spec)
          end
        end

        def setup_hash_spec
          raise HashCreatorKeyError.new unless spec.key?(:callee)
          raise HashCreatorCalleeError.new(spec[:callee]) unless callee_ok?
          raise HashCreatorArgsTypeError.new(spec[:args]) unless args_type_ok?

          @args = spec[:args]
          callee = spec[:callee]
          callee.is_a?(Method) ? setup_method_spec(callee) : setup_module_spec(callee)
        end

        def setup_method_spec(using = spec)
          @meth = using.name
          @mod = using.receiver
        end

        def setup_module_spec(using = spec)
          default_job_method = Kiba::Extend.default_job_method_name
          raise JoblessModuleCreatorError.new(using) unless using.private_method_defined?(default_job_method)

          @mod = using
          @meth = default_job_method
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
