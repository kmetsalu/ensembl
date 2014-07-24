require 'active_record'

module Ensembl
  module Variation
    class Connection < ActiveRecord::Base
      self.extend TableNameOverrides

      self.abstract_class = true

      self.establish_connection :adapter  => "mysql2",
                                :host     => Ensembl.host,
                                :username => Ensembl.username,
                                :password => Ensembl.password,
                                :database => Ensembl.species+'_variation_'+Ensembl.version+'_'+Ensembl.hg_version,
                                :reconnect => true

    end

    class ModelBase < Connection
      self.extend PrimaryKeyOverrides

      self.abstract_class = true
    end

    class Allele < ModelBase
      belongs_to :variation
      belongs_to :population
      belongs_to :subsnp_handle
      belongs_to :allele_code

    end

    class AlleleCode < ModelBase
      has_many :genotype_codes

    end

    class AssociateStudy < Connection
      belongs_to :study, foreign_key: 'study1_id', class_name: 'Study'
      belongs_to :associated_study, foreign_key: 'study2_id', class_name: 'Study'

    end

    class Attrib < ModelBase
      belongs_to :attrib_type
    end

    class AttribSet < ModelBase
      belongs_to :attrib

    end

    class AttribType < ModelBase
      has_many :attribs, class_name: 'Attrib'
      has_many :pheotype_feature_attrib
      has_many :phenotype_features, through: :phenotype_feature_attrib

    end

    class CompressedGenotypeRegion < Connection
      belongs_to :individual
      belongs_to :seq_region, class_name: 'Ensembl::Core::SeqRegion'
    end

    class CompressedGenotypeVar < Connection
      belongs_to :variation
      belongs_to :subsnp_handle, foreign_key: 'subsnp_id'

      def individual_genotypes
        nil if genotypes.nil?

        # To decrease number of DB queries needed
        # FIXME: Should be in GenotypeCodes class or should use caching
        genotype_codes=genotype_code_ids.uniq.inject({}) { |hsh, gc_id | hsh[gc_id]=GenotypeCode.find gc_id;hsh  }

        @igs||=unpacked_genotypes.map{|s| IndividualGenotype.new(s[0],s[1],genotype_codes[s[1]])}
      end

      def unpacked_genotypes
        unpack_genotypes.each_slice(2).map{|sl| sl }
      end

      def individual_ids
        unpack_genotypes.select.each_with_index{|str,i| i.even?}
      end

      def genotype_code_ids
        unpack_genotypes.select.each_with_index{|str,i| i.odd?}
      end

      protected
      def unpack_genotypes
        @g_unpacked||=genotypes.unpack('ww*') unless genotypes.nil?
      end
    end

    class CoordSystem < ModelBase
    end

    class FailedAllele < ModelBase
      belongs_to :failed_description
      belongs_to :allele

    end

    class FailedDescription < ModelBase
      belongs_to :failed_variation

    end

    class FailedStructuralVariation < ModelBase
      belongs_to :structural_variation
      belongs_to :failed_description

    end

    class FailedVariation < ModelBase
      belongs_to :variation
      has_one :failed_description

    end

    class GenotypeCode < ModelBase

      belongs_to :allele_code

    end

    class Individual < ModelBase
      belongs_to :individual_type
      belongs_to :father, foreign_key: 'father_individual_id', class_name: 'Individual'
      belongs_to :mother, foreign_key: 'mother_individual_id', class_name: 'Individual'

      has_many :individual_populations
      has_many :populations, through: :individual_populations

      has_many :individual_synonyms, foreign_key: :synonym_id
      has_many :synonyms, through: :individual_synonyms

      has_many :individual_genotype_multiple_bps

      scope :with_fathers, -> { where.not(father:nil) }
      scope :with_mothers, -> { where.not(mother:nil) }

    end

    class IndividualGenotype
      attr_reader :individual_id,:genotype_code_id

      # @individual_id - id to get #Individual from the database
      # @genotype_code_id - id to get #GenotypeCode from the database
      # @genotype_code - optimization to provide #GenotypeCode #TODO try to use cache
      def initialize(individual_id,genotype_code_id,genotype_code=nil)
        @individual_id = individual_id
        @genotype_code_id = genotype_code_id
        @genotype_code=genotype_code
      end

      def population_ids
        IndividualPopulation.where(individual_id: @individual_id)
      end

      def individual
        @individual||=Individual.find @individual_id
      end

      def genotype_code
        @genotype_code||=GenotypeCode.find @genotype_code_id
      end
    end

    class IndividualGenotypeMultipleBp < Connection
      belongs_to :variation
      belongs_to :individual
      belongs_to :subsnp_handle, foreign_key: 'subsnp_id'

    end

    class IndividualPopulation < Connection
      belongs_to :individual
      belongs_to :population
    end

    class IndividualSynonym < Connection
      belongs_to :individual
      belongs_to :source
      belongs_to :synonym, class_name: 'Individual'

    end

    class IndividualType < ModelBase
      has_many :individuals
    end

    class Meta < ModelBase
      # TODO: Link with others
    end

    class MetaCoord < Connection
    end

    class MotifFreatureVariation < ModelBase
      belongs_to :variation_feature
    end

    class Phenotype < ModelBase
      has_many :phenotype_features
    end

    class PhenotypeFeature < ModelBase
      # FIXME: Hack because using type column in the database
      self.inheritance_column = ':_no_inheritance_column'

      belongs_to :phenotype
      belongs_to :source
      belongs_to :study
      belongs_to :seq_region, class_name: 'Ensembl::Core::SeqRegion'

      has_many :phenotype_feature_attrib
      has_many :attrib_types, through: :phenotype_feature_attrib

      def variation
        Variation.find_by name: object_id
      end

    end

    class PhenotypeFeatureAttrib < Connection
      belongs_to :attrib_type
      belongs_to :phenotype_feature

    end

    class Population < ModelBase
      self.extend Ensembl::SearchByName

      has_many :population_synonyms
      #has_many :synonyms, through: :population_synonyms, source: :synonym
      has_many :alleles

      has_many :individual_populations
      has_many :individuals, through: :individual_populations

      has_many :population_structures, foreign_key: 'super_population_id'
      has_many :sub_populations, through: :population_structures, source: :sub_population
      has_many :parents, through: :population_structures, source: :super_populaton#, foreign_key: 'sub_population_id'

      has_many :population_genotypes

      def parent
        ps=PopulationStructure.find_by(sub_population: id)
        ps.super_population unless ps.nil?
      end

      def all_individual_populations
        IndividualPopulation.where(population_id: sub_population_ids(self)<<id)
      end

      def all_individuals
        Individual.where individual_id: all_individual_populations.pluck(:individual_id)
      end

      def all_population_genotypes
        PopulationGenotype.where(population_id: sub_population_ids(self)<<id)
      end

      private
        def sub_population_ids(population,array=[])
          subs=population.sub_populations
          subs.each do |p|
            array<<p.id
            sub_population_ids(p,array)
          end
        end
    end

    class PopulationSynonym < Connection
      #belongs_to :synonym, foreign_key: 'synonym_id', class_name: 'Population'
      belongs_to :population
      belongs_to :source
    end

    class PopulationGenotype < ModelBase
      belongs_to :variation
      belongs_to :population
      belongs_to :subsnp_handle, foreign_key: 'subsnp_id'
      belongs_to :genotype_code

      has_one :allele_code, through: :genotype_code
    end

    class PopulationStructure < Connection
      belongs_to :super_population, foreign_key: 'super_population_id', class_name: 'Population'
      belongs_to :sub_population, foreign_key: 'sub_population_id', class_name: 'Population'
    end

    class ProteinFunctionPredictions < Connection

    end

    class Publication < ModelBase

    end

    class RegulatoryFeatureVariation < ModelBase
      belongs_to :variation_feature
    end

    # class SeqRegion < Ensembl::Core::SeqRegion
    #   belongs_to :coord_system
    #   has_many :compressed_genotype_regions
    #   has_many :phenotype_features
    #   has_many :structureal_variation_features
    # end

    class StrainGtypePoly < Connection
      belongs_to :variation

    end

    class StructuralVariation < ModelBase
      belongs_to :source
      belongs_to :study

      belongs_to :class_attrib, foreign_key: 'class_attrib_id', class_name: 'Attrib'
      has_one :classification, through: :class_attrib, source: :attrib_type

      belongs_to :clinical_significance_attrib, foreign_key: 'clinical_significance_id', class_name: 'Attrib'
      has_one :clinical_significance, through: :clinical_significance_attrib, source: :attrib_type

      has_many :structural_variation_associations
      has_many :supporting_structural_variations, through: :structural_variation_associations

      has_many :structural_variation_samples
      has_many :individuals, through: :structural_variation_samples, source: :individual

      has_many :variation_sets

      scope :with_supporting_structural_variations, -> { joins(:structural_variation_associations).where.not structural_variation_associations: nil }

    end

    class StructuralVariationAssociation < Connection
      belongs_to :structural_variation
      belongs_to :supporting_structural_variation, foreign_key: 'supporting_structural_variation_id', class_name: 'StructuralVariation'
    end

    class StructuralVariationFeature < ModelBase
      belongs_to :seq_region, class_name: 'Ensembl::Core::SeqRegion'
      belongs_to :structural_variation
      belongs_to :source
      belongs_to :study
      belongs_to :variation_set

      belongs_to :class_attrib, foreign_key: 'class_attrib_id', class_name: 'Attrib'
      has_one :classification, through: :class_attrib, source: :attrib_type

    end

    class StructuralVariationSample < ModelBase
      belongs_to :structural_variation
      belongs_to :individual
      belongs_to :strain, foreign_key: 'strain_id', class_name: 'Individual'
    end

    class Source < ModelBase
    end

    class Study < ModelBase
      has_many :associate_studies, foreign_key: 'study1_id'
      has_many :associated_studies, through: :associate_studies, source: :associated_study

      # FIXME: No data in database
      has_many :study_variations
      has_many :variations, through: :study_variations
    end

    # FIXME: No data in database
    class StudyVariation < Connection
      belongs_to :study
      belongs_to :variation
    end

    class SubmitterHandle < Connection
      self.primary_key = 'handle_id'
    end

    class SubsnpHandle < Connection
      self.primary_key = 'subsnp_id'

      has_many :subsnp_maps
    end

    class SubsnpMap < Connection
      belongs_to :variation
      belongs_to :subsnp_handle, foreign_key: 'subsnp_id'
    end

    class TaggedVariationFeature < ModelBase
      belongs_to :variation_feature
      belongs_to :population
    end

    class TranscriptVariation < ModelBase
      belongs_to :variation_feature

    end

    class TranslationMd5 < ModelBase

    end

    class Variation < ModelBase
      self.extend Ensembl::SearchByName

      belongs_to :source

      has_many :variation_synonyms

      has_many :failed_variations
      has_many :alleles
      has_many :population_genotypes
      has_many :study_variations
      has_many :studies, through: :study_variations
      has_many :variation_citations
      has_many :publications, through: :variation_citations
      has_many :subsnp_maps
      has_many :variation_genenames
      has_many :variation_hgvs, class_name: 'VariationHgvs'
      has_many :variation_sets
      has_many :variation_features

      has_many :individual_genotype_multiple_bps
      has_many :compressed_genotype_vars

      def phenotype_features
        PhenotypeFeature.where(object_id: name, type: 'Variation')
      end

      def synonyms
        variation_synonyms.map{ |vs| vs.name }
      end


      # Find Variation by also using VariationSynonyms
      # @name: name of the variation
      # @return: [Variation]
      def self.find_by_name(name)
        v  = self.find_by(name: name)
        vs = VariationSynonym.eager_load(:variation).find_by(name: name) if v.nil?
        vs.variation unless vs.nil?
      end

      def all_phenotype_features
        object_ids = variation_synonyms.pluck :name
        object_ids<<name
        PhenotypeFeature.where(object_id: object_ids, type: 'Variation')
      end

      # def population_genotypes
      #   PopulationGenotype.where(variation_id: id)
      # end
    end

    class VariationCitation < Connection
      self.table_name = 'variation_citation'
      belongs_to :variation
      belongs_to :publication
    end

    class VariationFeature < ModelBase
      belongs_to :variation
      belongs_to :source
      belongs_to :seq_region, class_name: 'Ensembl::Core::SeqRegion'

      has_many :transcript_variations
      has_many :motif_freature_variations
      has_many :tagged_variation_features

      def variation_sets
        VariationSets.where[variation_set_id: [variation_set_id.split(',').map{|id| id.to_i }]] unless variation_set_id.nil?
      end

      def class_type
        Attrib.find(class_attrib_id) unless class_attrib_id.nil?
      end
    end

    class VariationGenename < Connection
      belongs_to :variation
    end

    class VariationHgvs < Connection
      belongs_to :variation
    end

    class VariationSet < ModelBase
      self.extend Ensembl::SearchByName

      belongs_to :short_name, foreign_key: 'short_name_attrib_id', class_name: 'Attrib'
      has_many :structural_variations

      #has_many :variation_set_structures, foreign_key: 'variation_set_super'
      has_many :sub_variation_set_structures, foreign_key: 'variation_set_super', class_name: 'VariationSetStructure'
      has_many :sub_variation_sets, through: :sub_variation_set_structures , source: :sub_variation_set

      has_many :super_variation_set_structures, foreign_key: 'variation_set_sub', class_name: 'VariationSetStructure'
      has_many :super_variation_sets, through: :super_variation_set_structures , source: :super_variation_set

      has_many :variation_set_variations
      has_many :variations, through: :variation_set_variations

    end

    class VariationSetStructuralVariation < Connection
      belongs_to :structural_variation
      belongs_to :variation_set
    end

    class VariationSetStructure < Connection
      belongs_to :super_variation_set, foreign_key: 'variation_set_super', class_name: 'VariationSet'
      belongs_to :sub_variation_set, foreign_key: 'variation_set_sub', class_name: 'VariationSet'
    end

    class VariationSetVariation < Connection
      belongs_to :variation
      belongs_to :variation_set
    end

    class VariationSynonym < ModelBase
      belongs_to :variation
      belongs_to :source
    end
  end
end