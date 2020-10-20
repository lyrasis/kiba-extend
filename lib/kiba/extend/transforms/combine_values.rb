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
            vals = @sources.map{ |src| row.fetch(src, nil) }
              .map{ |v| v.blank? ? nil : v }
            
            if @prepend
              pvals = []
              vals.each_with_index do |val, i|
                val = "#{@sources[i]}: #{val}" unless val.nil?
                pvals << val
              end
              vals = pvals
            end
            val = vals.compact.join(@sep)
            val.empty? ? row[@target] = nil : row[@target] = val
            
            @sources.each{ |src| row.delete(src) unless src == @target } if @del
            row
          end
        end

        class FullRecord
          def initialize(target:, sep: ' ')
            @target = target
            @sep = sep
          end

          def process(row)
            vals = row.keys.map{ |k| row.fetch(k, nil) }
            vals = vals.compact
            if vals.empty?
              row[@target] = nil
            else
              row[@target] = vals.join(@sep)
            end
            row
          end
        end
      end
    end
  end
end
