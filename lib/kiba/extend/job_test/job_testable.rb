# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      # Mixin module containing general JobTest behavior
      module JobTestable
        # Keys get dynamically set as instance variables in the concrete
        #   test classes, so they can't contain characters disallowed in
        #   instance variable names
        ALLOWED_CONFIG_KEY_PATTERN = /^[a-z_]+$/

        # @return [Hash]
        def result
          run
          config[:desc] = desc
          if run == :success
            config.merge({status: run})
          else
            config.merge({status: :failure, got: run})
          end
        end

        private

        def initialization_logic(config)
          instance_variable_set(:@config, config)
          validate_config(config)
          config.each { |key, val| generate_instance_variable(key, val) }
        end

        def config = @config

        def job_data = @job_data ||= get_job_data

        def validate_config(config)
          unless config.key?(:path)
            fail("#{self.class.name} requires a :path key in its config")
          end

          validate_other_keys(config) if respond_to?(:required_keys, true)

          invalid_keys = config.keys
            .map(&:to_s)
            .reject { |key| key.match?(ALLOWED_CONFIG_KEY_PATTERN) }
          return if invalid_keys.empty?

          fail("The following values cannot be used as config keys for "\
               "#{self.class.name} tests: #{invalid_keys.join(", ")}")
        end

        def validate_other_keys(config)
          missing = required_keys.reject { |k| config.key?(k) }
          return if missing.empty?

          raise("#{self.class.name} config requires key(s): "\
                "#{missing.join(", ")}")
        end

        def generate_instance_variable(key, val)
          iv = :"@#{key}"
          instance_variable_set(iv, val)
          self.class.define_method(key) { instance_variable_get(iv) }
        end
      end
    end
  end
end
