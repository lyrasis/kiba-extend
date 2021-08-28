require_relative 'source_dest_registry'

module Kiba
  module Extend
    # Value object capturing the data about an entry in the file registry
    #
    # This is the underlying data that can be used to derive a registered source,
    #   destination, or lookup file object.
    #
    # Used instead of just passing around a Hash so that it can validate itself and
    #   carry its own errors/warnings
    class FileRegistryEntry
      include SourceDestRegistry

      attr_reader :path, :key,
        :creator, :supplied, :dest_special_opts, :desc, :lookup_on, :tags, :message,
        :dest_class, :dest_opt, :src_class, :src_opt,
        :valid, :errors, :warnings

      # @param reghash [Hash] File data. See {file:doc/file_registry_entry.md} for details
      def initialize(reghash)
        set_defaults
        assign_values_from(reghash)
        validate
      end

      def set_key(key)
        @key = key
      end
      
      def summary
        "#{key} -- #{tags.join(', ')}\n  #{path}\n  #{desc}"
      end

      def valid?
        valid
      end

      private

      def allowed_settings
        self.instance_variables
          .map(&:to_s)
          .map{ |str| str.delete_prefix('@') }
          .map(&:to_sym)
      end

      def allowed_setting?(key)
        allowed_settings.any?(key)
      end
      
      def assign_value(key, val)
        if allowed_setting?(key)
          self.instance_variable_set("@#{key}".to_sym, val)
        else
          @warnings << ":#{key} is not an allowed FileRegistryEntry setting"
        end
      end
      
      def assign_values_from(reghash)
        reghash.each{ |key, val| assign_value(key, val) }
      end

      def path_required?
        chk = [dest_class, src_class].map{ |klass| requires_path?(klass) }
        return false if chk.uniq == [false]

        true
      end
      
      def set_defaults
        @creator = nil
        @desc = ''
        @dest_class = Kiba::Extend.destination
        @dest_opt = Kiba::Extend.csvopts
        @dest_special_opts = nil
        @lookup_on = nil
        @path = nil
        @src_class = Kiba::Extend.source
        @src_opt = Kiba::Extend.csvopts
        @supplied = false
        @tags = []
        @valid = false
        @errors = {}
        @warnings = []
      end

      def validate
        validate_path
        validate_creator
        @valid = true if errors.empty?
      end

      def validate_creator
        return if supplied

        unless creator
          @errors[:missing_creator_for_non_supplied_file] = nil
          return
        end
        
        unless creator.is_a?(Method)
          @errors[:creator_not_a_method] = creator.dup
          @creator = nil
        end
      end

      def validate_path
        if path_required? && !path
          @errors[:missing_path] = nil
          return
        end
        
        @path = Pathname.new(path) if path
      end
    end
  end
end