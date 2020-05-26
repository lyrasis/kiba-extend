module Kiba
  module Extend
    module Transforms
      module Reshape
        ::Reshape = Kiba::Extend::Transforms::Reshape

        # Takes multiple fields like :workphone, :homephone, :mobilephone
        #   and produces two new fields like :phone and :phonetype
        #   where :phonetype depends on the original field taken from

        # sourcefieldmap = hash where key is source field and value is the type to
        #  be assigned
        # datafield = target field for original values
        # typefield = target field for original value types
        # sourcesep = string, multivalued delimiter of source data
        # targetsep = string, multivalued delimiter of target data
        # delete_sources = boolean, defaults to true
        class CollapseMultipleFieldsToOneTypedFieldPair
          def initialize(sourcefieldmap:, datafield:, typefield:, sourcesep: nil, targetsep:, delete_sources: true)
            @map = sourcefieldmap
            @df = datafield
            @tf = typefield
            @sourcesep = sourcesep
            @targetsep = targetsep
            @del = delete_sources
          end

          def process(row)
            data = []
            type = []
            @map.keys.each do |sourcefield|
              vals = row.fetch(sourcefield)
              unless vals.nil?
                vals.split(@sourcesep).each do |val|
                  data << val
                  type << @map.fetch(sourcefield, @default_type)
                end
              end
              row.delete(sourcefield) if @del
            end
            row[@df] = data.size > 0 ? data.join(@targetsep) : nil
            row[@tf] = type.size > 0 ? type.join(@targetsep) : nil
            row
          end
        end
      end
    end
  end
end
