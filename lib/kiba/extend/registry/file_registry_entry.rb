# frozen_string_literal: true

module Kiba
  module Extend
    module Registry
      # Captures the data about an entry in the file registry
      #
      # This is the underlying data that can be used to derive a registered
      #   source, destination, or lookup file object.
      #
      # Used instead of just passing around a Hash so that it can validate
      #   itself and carry its own errors/warnings
      class FileRegistryEntry
        include EntrySummarizable

        attr_reader :path, :key,
          :creator, :supplied, :dest_special_opts, :desc, :lookup_on, :tags,
          :message, :dest_class, :dest_opt, :src_class, :src_opt, :type,
          :valid, :errors, :warnings

        # allowed types
        TYPES = :file, :fileset, :enum, :lambda

        # @param key [Symbol] Full job key associated with reghash
        # @param reghash [Hash] File data. See {file:doc/file_registry_entry.md}
        #   for details
        def initialize(key, reghash)
          @key = key
          @type = :file
          @creator = nil
          @desc = ""
          @dest_class = Kiba::Extend.destination
          @dest_opt = nil
          @dest_special_opts = nil
          @lookup_on = nil
          @path = nil
          @src_class = Kiba::Extend.source
          @src_opt = nil
          @supplied = false
          @tags = []
          @valid = false
          @errors = {}
          @warnings = []
          assign_values_from(reghash)
          validate
        end

        def dir = path.dirname

        # Whether the Entry is valid
        # @return [Boolean]
        def valid? = valid

        private

        def assign_values_from(reghash)
          reghash.each { |key, val| assign_value(key, val) }
        end

        def assign_value(key, val)
          if allowed_setting?(key)
            if key == :dest_special_opts
              val.transform_values! { |v| v.is_a?(Proc) ? v.call : v }
            elsif key == :creator
              val = set_up_creator(val)
            else
              val = val.is_a?(Proc) ? val.call : val
            end

            instance_variable_set(:"@#{key}", val)
          else
            @warnings << ":#{key} is not an allowed FileRegistryEntry setting"
          end
        end

        def allowed_setting?(key) = allowed_settings.any?(key)

        def allowed_settings
          instance_variables
            .map(&:to_s)
            .map { |str| str.delete_prefix("@") }
            .map(&:to_sym)
        end

        def set_up_creator(creator)
          @creator = Kiba::Extend::Registry::Creator.new(creator)
        rescue Kiba::Extend::Error => err
          errors[err.class.name] = err.message
        end

        def path_required?
          chk = [dest_class, src_class].map do |klass|
            klass.requires_path?
          end
          return false if chk.uniq == [false]

          true
        end

        def validate
          validate_path
          validate_creator
          validate_type
          validate_lookup
          @valid = true if errors.empty?
        end

        def validate_creator
          return if supplied
          return if creator.is_a?(Kiba::Extend::Registry::Creator)

          @creator = nil
          @errors[:missing_creator_for_non_supplied_file] = nil
        end

        def validate_lookup
          return unless lookup_on

          supplied ? validate_supplied_lookup : validate_job_lookup
        end

        def validate_job_lookup
          return if dest_class.as_source_class
            .respond_to?(:is_lookupable)

          @errors[:cannot_lookup_from_nonCSV_destination] = nil
        end

        def validate_supplied_lookup
          return if src_class.name.end_with?("CSV")

          @errors[:cannot_lookup_from_nonCSV_supplied_source] = nil
        end

        def validate_path
          if path_required? && !path
            @errors[:missing_path] = nil
            return
          end

          @path = Pathname.new(path) if path
        end

        def validate_type
          return if TYPES.any?(@type)

          @errors[:unknown_type] = @type
        end
      end
    end
  end
end
