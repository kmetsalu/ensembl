require 'active_record'

module Ensembl
  module Variation
    class Allele < Ensembl::ModelBase
      belongs_to :variation
      belongs_to :population
      belongs_to :subsnp_handle
      belongs_to :allele_code

    end

    class AlleleCode < Ensembl::ModelBase
      has_many :genotype_codes

    end

    class AssociateStudy < Ensembl::Connection
      belongs_to :study, foreign_key: 'study1_id', class_name: 'Study'
      belongs_to :associated_study, foreign_key: 'study2_id', class_name: 'Study'

    end

    class Attrib < Ensembl::ModelBase
      belongs_to :attrib_type

    end

    class AttribSet < Ensembl::ModelBase
      belongs_to :attrib

    end

    class AttribType < Ensembl::ModelBase
      has_many :attribs, class_name: 'Attrib'
      has_many :pheotype_feature_attrib
      has_many :phenotype_features, through: :phenotype_feature_attrib

    end

    class CompressedGenotypeRegion < Ensembl::Connection
      belongs_to :individual

    end

    class CompressedGenotypeVar < Ensembl::Connection
      belongs_to :variation
      belongs_to :subsnp_handle, foreign_key: 'subsnp_id'

    end

    class CoordSystem < Ensembl::ModelBase
    end

    class FailedAllele < Ensembl::ModelBase
      belongs_to :failed_description
      belongs_to :allele

    end

    class FailedDescription < Ensembl::ModelBase
      belongs_to :failed_variation

    end

    class FailedStructuralVariation < Ensembl::ModelBase
      belongs_to :structural_variation
      belongs_to :failed_description

    end

    class FailedVariation < Ensembl::ModelBase
      belongs_to :variation
      has_one :failed_description

    end

    class GenotypeCode < Ensembl::ModelBase
      belongs_to :allele_code
      belongs_to :genotype_code

    end

    class Individual < Ensembl::ModelBase
      belongs_to :individual_type
      belongs_to :father, foreign_key: 'father_individual_id', class_name: 'Individual'
      belongs_to :mother, foreign_key: 'mother_individual_id', class_name: 'Individual'

      has_many :individual_populations
      has_many :populations, through: :individual_populations

      has_many :individual_synonyms, foreign_key: :synonym_id
      has_many :synonyms, through: :individual_synonyms

      scope :with_fathers, -> { where.not(father:nil) }
      scope :with_mothers, -> { where.not(mother:nil) }

    end

    class IndividualGenotypeMultipleBp < Ensembl::Connection
      belongs_to :variation
      belongs_to :individual
      belongs_to :subsnp_handle, foreign_key: 'subsnp_id'

    end

    class IndividualPopulation < Ensembl::Connection
      belongs_to :individual
      belongs_to :population

    end

    class IndividualSynonym < Ensembl::Connection
      belongs_to :individual
      belongs_to :source
      belongs_to :synonym, class_name: 'Individual'

    end

    class IndividualType < Ensembl::ModelBase
      has_many :individuals
    end

    class Meta < Ensembl::ModelBase
      # TODO: Link with others
    end

    class MetaCoord < Ensembl::Connection
    end

    class MotifFreatureVariation < Ensembl::ModelBase
      belongs_to :variation_feature
    end

    class Phenotype < Ensembl::ModelBase
      has_many :phenotype_features
    end

    class PhenotypeFeature < Ensembl::ModelBase
      # Hack because using type column in the database
      self.inheritance_column = ':_no_inheritance_column'

      belongs_to :phenotype
      belongs_to :source
      belongs_to :study

      has_many :phenotype_feature_attrib
      has_many :attrib_types, through: :phenotype_feature_attrib

      def variation
        Variation.find_by name: object_id
      end

    end

    class PhenotypeFeatureAttrib < Ensembl::Connection
      belongs_to :attrib_type
      belongs_to :phenotype_feature

    end

    class Population < Ensembl::ModelBase
      has_many :population_synonyms
      has_many :synonyms, through: :population_synonyms, source: :synonym
      has_many :alleles

      has_many :individual_populations
      has_many :individuals, through: :individual_populations

      has_many :population_structures, foreign_key: 'super_population_id'
      has_many :sub_populations, through: :population_structures, source: :sub_population

      has_many :population_genotypes

      def all_individual_populations
        IndividualPopulation.where(population_id: sub_populations.pluck(:population_id))
      end

      def all_individuals
        Individual.where individual_id: all_individual_populations.pluck(:individual_id)
      end

    end

    class PopulationSynonym < Ensembl::Connection
      belongs_to :synonym, foreign_key: 'synonym_id', class_name: 'Population'
      belongs_to :population
      belongs_to :source
    end

    class PopulationGenotype < Ensembl::ModelBase
      belongs_to :variation
      belongs_to :population
      belongs_to :subsnp_handle, foreign_key: 'subsnp_id'
      belongs_to :genotype_code

    end

    class PopulationStructure < Ensembl::Connection
      belongs_to :population, foreign_key: 'super_population_id', class_name: 'Population'
      belongs_to :sub_population, foreign_key: 'sub_population_id', class_name: 'Population'

    end

    class ProteinFunctionPredictions < Ensembl::Connection
    end

    class Publication < Ensembl::ModelBase
    end

    class RegulatoryFeatureVariation < Ensembl::ModelBase
      belongs_to :variation_feature

    end

    class SeqRegion < Ensembl::ModelBase
      belongs_to :coord_system

    end

    class StrainGtypePoly < Ensembl::Connection
      belongs_to :variation

    end

    class StructuralVariation < Ensembl::ModelBase
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

    class StructuralVariationAssociation < Ensembl::Connection
      belongs_to :structural_variation
      belongs_to :supporting_structural_variation, foreign_key: 'supporting_structural_variation_id', class_name: 'StructuralVariation'
    end

    class StructuralVariationFeature < Ensembl::ModelBase
      belongs_to :seq_region
      belongs_to :structural_variation
      belongs_to :source
      belongs_to :study
      belongs_to :variation_set

      belongs_to :class_attrib, foreign_key: 'class_attrib_id', class_name: 'Attrib'
      has_one :classification, through: :class_attrib, source: :attrib_type

    end

    class StructuralVariationSample < Ensembl::ModelBase
      belongs_to :structural_variation
      belongs_to :individual
    end

    class Study < Ensembl::ModelBase
      has_many :study_variations
      has_many :variations, through: :study_variations

    end

    class Source < Ensembl::ModelBase

    end

    class Study < Ensembl::ModelBase
      has_many :associate_studies, foreign_key: 'study1_id'
      has_many :associated_studies, through: :associate_studies, source: :associated_study

      # FIXME: No data in database
      has_many :variations, through: :study_variations
    end

    # FIXME: No data in database
    class StudyVariation < Ensembl::Connection
      belongs_to :study
      belongs_to :variation
    end

    class SubmitterHandle < Ensembl::Connection
      self.primary_key = 'handle_id'
    end

    class SubsnpHandle < Ensembl::Connection
      self.primary_key = 'subsnp_id'

      has_many :subsnp_maps
    end

    class SubsnpMap < Ensembl::Connection
      belongs_to :variation
      belongs_to :subsnp_handle, foreign_key: 'subsnp_id'
    end

    class TaggedVariationFeature < Ensembl::ModelBase
      belongs_to :variation_feature
      belongs_to :population
    end

    class TranscriptVariation < Ensembl::ModelBase
      belongs_to :variation_feature

    end

    class TranslationMd5 < Ensembl::ModelBase

    end

    class Variation < Ensembl::ModelBase
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

      def phenotype_features
        PhenotypeFeature.where(object_id: name, type: 'Variation')
      end

      def all_phenotype_features
        object_ids = variation_synonyms.pluck :name
        object_ids<<name
        PhenotypeFeature.where(object_id: object_ids, type: 'Variation')
      end
    end

    class VariationCitation < Ensembl::Connection
      self.table_name = 'variation_citation'
      belongs_to :variation
      belongs_to :publication
    end

    class VariationFeature < Ensembl::ModelBase
      belongs_to :variation
      belongs_to :source
      has_many :transcript_variations
      has_many :motif_freature_variations
      has_many :tagged_variation_features

    end

    class VariationGenename < Ensembl::Connection
      belongs_to :variation
    end

    class VariationHgvs < Ensembl::Connection
      belongs_to :variation
    end

    class VariationSet < Ensembl::ModelBase
      belongs_to :short_name, foreign_key: 'short_name_attrib_id', class_name: 'Attrib'
      has_many :structural_variations

      has_many :variation_set_structures
      has_many :sub_variation_sets, through: :variation_set_structures, source: :sub_variation_set

      has_many :variations
    end

    class VariationSetStructuralVariation < Ensembl::Connection
      belongs_to :structural_variation
      belongs_to :variation_set
    end

    class VariationSetStructure < Ensembl::Connection
      belongs_to :super_variation_set, foreign_key: 'super_variation_set_id', class_name: 'VariationSet'
      belongs_to :sub_variation_set, foreign_key: 'sub_variation_set_id', class_name: 'VariationSet'
    end

    class VariationSetVariation < Ensembl::Connection
      belongs_to :variation
      belongs_to :variation_set
    end

    class VariationSynonym < Ensembl::ModelBase
      belongs_to :variation
      belongs_to :source
    end


  end
end