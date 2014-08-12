module Ensembl
  module Helpers
    #TODO: Implement phased
    class Genotype
      def initialize(attrib)
        @left=attrib[1]
        @right=attrib[2]
      end
    end

    class VariationPosition
      attr_reader :chromosome,:start_pos,:end_pos

      def initialize(row)
        @chromosome,@start_pos,@end_pos,@strand=row
      end

      def strand
        if @strand==1
          return 'forward'
        end
        'reverse'
      end

      def to_s
        'Chromosome: ' + @chromosome + ' ' + @start_pos.to_s + ':' + @end_pos.to_s
      end
    end
  end
end