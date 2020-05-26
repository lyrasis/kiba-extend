module Kiba
  module Extend
    module Transforms
      module CombineValues
        ::CombineValues = Kiba::Extend::Transforms::CombineValues
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
            @sources.each{ |src| row.delete(src) } if @del
            row
          end
        end
      end
    end
  end
end
