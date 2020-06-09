module Kiba
  module Extend
    module Transforms
      module CombineValues
        ::CombineValues = Kiba::Extend::Transforms::CombineValues
        class AcrossFieldGroup
          def initialize(fieldmap:, sep:, delete_sources: true)
            @fieldmap = fieldmap
            @sep = sep
            @del = delete_sources
          end

          def process(row)
            @fieldmap.each do |target, sources|
              vals = []
              sources.each do |source|
                srcval = row.fetch(source)
                vals << '' if srcval.nil? || srcval.empty? || srcval.match?(Regexp.new("^#{@sep}"))
                vals << srcval.split(@sep) unless srcval.nil? || srcval.empty?
                vals << '' if srcval.match?(Regexp.new("#{@sep}$")) unless srcval.nil? || srcval.empty?
                row.delete(source) unless source == target if @del
              end
              row[target] = vals.join(@sep)
            end
            row
          end
        end
        
        class FromFieldsWithDelimiter
          def initialize(sources:, target:, sep:, prepend_source_field_name: false, delete_sources: true)
            @sources = sources
            @target = target
            @sep = sep
            @del = delete_sources
            @prepend = prepend_source_field_name
          end

          def process(row)
            if @prepend
              vals = []
              @sources.each do |src|
                val = row.fetch(src)
                vals << "#{src}: #{val}" unless val.nil? || val.empty?
              end
              val = vals.compact.join(@sep)
            else
              val = @sources.map{ |src| row.fetch(src) }.compact.join(@sep)
            end
            
            val.empty? ? row[@target] = nil : row[@target] = val
            @sources.each{ |src| row.delete(src) unless src == @target } if @del
            row
          end
        end
      end
    end
  end
end
