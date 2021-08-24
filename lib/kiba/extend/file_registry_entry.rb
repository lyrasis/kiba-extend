require 'kiba/extend'

module Kiba
  module Extend
    class FileRegistryEntry
      attr_reader :creator, :desc, :dest_class, :dest_opt, :dest_special_opts, :lookup_on,
        :path, :src_class, :src_opt, :valid, :errors, :warnings
      def initialize(reghash)
        set_defaults
        assign_values_from(reghash)
        validate
      end

      def valid?
        valid
      end

      private

      def allowed_settings
        @allowed_settings ||= self.instance_variables
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
      
      def set_defaults
        @creator = nil
        @desc = ''
        @dest_class = nil
        @dest_opt = Kiba::Extend.csvopts
        @dest_special_opts = nil
        @lookup_on = nil
        @path = nil
        @src_class = nil
        @src_opt = Kiba::Extend.csvopts
        @valid = false
        @errors = {}
      end

      def validate
        @errors[:missing_path] = nil unless path
        validate_creator
        @valid = true if errors.empty?
      end

      def validate_creator
        return unless creator
        
        unless creator.is_a?(Method)
          @errors[:creator_not_a_method] = creator.dup
          @creator = nil
        end
      end
    end
  end
end
