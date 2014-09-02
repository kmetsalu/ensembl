require 'active_record'

module Ensembl
  module Variation

    # ConnectionPool implemented from:
    # http://www.lucasallan.com/2014/05/26/fixing-concurrency-issues-with-active-record-in-a-rack-application.html
    class Connection < ActiveRecord::Base

      self.extend Ensembl::TableNameOverrides

      self.abstract_class = true

      self.establish_connection :variation

      # ConnectionPool implemented from:
      # http://www.lucasallan.com/2014/05/26/fixing-concurrency-issues-with-active-record-in-a-rack-application.html
      singleton_class.send(:alias_method, :original_connection, :connection)

      def self.connection
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn
        end
      end
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
      # self.extend AttributeLike

      belongs_to :attrib_type
    end

    class AttribSet < ModelBase
      belongs_to :attrib
    end

    class AttribType < ModelBase

      has_many :attribs, class_name: 'Attrib'
      has_many :pheotype_feature_attrib
      has_many :phenotype_features, through: :phenotype_feature_attrib

      scope :common_values, -> { where(attrib_type_id: self.mapping_hash.keys)}

      def self.mapping_hash
        @mapping_hash||={14=>:risk_allele,15=>:p_value,23=>:odds_ratio,24=>:beta}
      end

      def self.key(value)
        mapping_hash.key(value)
      end

      def self.symbol(key)
        mapping_hash[key]
      end
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
        allele_codes=GenotypeCode.eager_load(:allele_code).where(:genotype_code_id=>genotype_code_ids.uniq).inject({}){|hsh,gc|hsh[gc.genotype_code_id]=gc.allele_code.allele;hsh}

        @igs||=unpacked_genotypes.map{|s|
          IndividualGenotype.new({ individual_id:  s[0],
                                   genotype_code_id: s[1],
                                   allele: allele_codes[s[1]] })}
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

      def self.genotype_for(genotype_code_id)
        joins(:allele_code).where(genotype_code_id: genotype_code_id).order(:haplotype_id).pluck('allele_code.allele').join('|')
      end

      def self.genotypes_for(genotype_code_ids)
        includes(:allele_code).where(genotype_code_id: genotype_code_ids).pluck('genotype_code.genotype_code_id','genotype_code.haplotype_id','allele_code.allele').group_by{|r| r[0]}.map{|k,v| [k,v.sort_by{|f,s| f[1]<=>s[1]}.map{|v| v[2]}.join('|')]}
      end

      def self.genotypes_hash_for(genotype_code_ids)
        genotypes_for(genotype_code_ids).to_h
      end
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

    class IndividualGenotypeMultipleBp < Connection
      belongs_to :variation
      belongs_to :individual
      belongs_to :subsnp_handle, foreign_key: 'subsnp_id'

    end

    class IndividualPopulation < Connection
      belongs_to :individual
      belongs_to :population

      scope :displayable, -> { joins(:population).merge(Population.displayable) }
      scope :thousand_genomes, -> { joins(:population).merge(Population.thousand_genomes)}

      scope :by_individual_ids, ->(ids) { where(individual_id: ids) }


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

      def studies
        ids=phenotype_features
        .with_studies
        .uniq
        .pluck(:study_id)

        return nil unless ids.size > 0 #

        Study.where(study_id: ids)
      end
    end

    class PhenotypeFeature < ModelBase
      # FIXME: Hack because using type column in the database
      self.inheritance_column = ':_no_inheritance_column'

      alias_attribute :object_id_column, :object_id

      belongs_to :phenotype
      belongs_to :source
      belongs_to :study
      belongs_to :seq_region, class_name: 'Ensembl::Core::SeqRegion'

      has_one :variation, primary_key: 'object_id', foreign_key: 'name'

      has_many :phenotype_feature_attribs
      has_many :attrib_types, through: :phenotype_feature_attribs

      scope :significant, -> { where(is_significant: true )}
      scope :with_studies, -> { where.not(study_id:nil)}

      # def variation
      #   Variation.find_by name: object_id
      # end

      def risk_allele
        pf=phenotype_feature_attribs.risk_alleles.first
        pf.value unless pf.nil?
      end

      def p_value
        pf=phenotype_feature_attribs.p_values.first
        pf.value unless pf.nil?
      end

      def odds_ratio
        pf=phenotype_feature_attribs.odds_ratios.first
        pf.value unless pf.nil?
      end

      def description
        phenotype.description
      end

    end

    class PhenotypeFeatureAttrib < Connection
      belongs_to :attrib_type
      belongs_to :phenotype_feature

      scope :risk_alleles, -> {
        where(attrib_type_id: AttribType.key(:risk_allele)) }

      scope :p_values, -> {
        where(attrib_type_id: AttribType.key(:p_value)) }

      scope :odds_ratios, -> {
        where(attrib_type_id: AttribType.key(:odds_ratio))}

      scope :betas, -> {
        where(attrib_type_id: AttribType.key(:beta))}
    end

    class Population < ModelBase
      # self.extend Ensembl::AttributeLike

      has_many :alleles
      has_many :population_synonyms

      has_many :individual_populations
      has_many :individuals, through: :individual_populations

      has_many :sub_population_structures, foreign_key: 'super_population_id', class_name: 'PopulationStructure'
      has_many :sub_populations, through: :population_structures, source: :sub_population

      has_many :super_population_structures, foreign_key: 'sub_population_id', class_name: 'PopulationStructure'
      has_many :super_populations, through: :population_structures, source: :super_populaton

      has_many :population_genotypes

      scope :displayable, -> { where(display:'LD')}
      scope :thousand_genomes, -> { displayable.starts_with(:name,'1000GENOMES')}

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
      has_many :studies

      scope :no_db_gap, -> { where.not(source_id: 46)}
    end

    class Study < ModelBase
      # include AttributeLike

      default_scope -> { includes(:source) }

      belongs_to :source

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
        PhenotypeFeature.eager_load(:phenotype).where(object_id_column: name, type: 'Variation')
      end

      def all_phenotype_features
        object_ids = synonym_names
        object_ids<<name
        PhenotypeFeature.eager_load(:phenotype).where(object_id: object_ids, type: 'Variation')
      end

      # Made because of the need to cut down database queries
      # @return
      # { phenotype_feature_id =>
      #   { :phenotype=> "Phenotype description" ,
      #     :phenotype_id => _ ,
      #     :p_value => _ ,
      #     :odds_ratio => _,
      #     :risk_allele => _ },
      #  phenotype_feature_id =>
      #   { :phenotype=> "Phenotype description" ,
      #     :phenotype_id => _ ,
      #     :p_value => _ ,
      #     :odds_ratio => _,
      #     :risk_allele => _ }}
      def phenotype_features_hash

        # Do enable two level inserts hsh[:first][:second]
        hash=Hash.new{ |hsh,key| hsh[key] = Hash.new {} }

        all_phenotype_features
        .joins(:phenotype)
        .pluck(
            :phenotype_feature_id,
            'phenotype.description',
            :phenotype_id)
        .each{ |r| hash[r[0]][:phenotype]=r[1]; hash[r[0]][:phenotype_id]=r[2]}

        PhenotypeFeatureAttrib
        .where(phenotype_feature_id: hash.keys)
        .pluck(
            'phenotype_feature_attrib.phenotype_feature_id',
            'phenotype_feature_attrib.value',
            'phenotype_feature_attrib.attrib_type_id')
        .each{ |v| hash[v[0]][AttribType.symbol(v[2])]=v[1] }

        hash
      end

      def synonym_names
        variation_synonyms.map{|vs| vs.name}
      end

      # Genotype counts for each population
      # @returns {"CSHL-HAPMAP:HapMap-CEU"=>{"C|T"=>59, "C|C"=>102, "T|T"=>12},
      # "CSHL-HAPMAP:HapMap-YRI"=>{"C|C"=>172, "C|T"=>1}}
      def genotype_counts
        counts = Hash.new{ |hsh,k| hsh[k] = Hash.new 0 }

        individual_populations.pluck('population.name',:individual_id).map{|ip| [ip[0],genotype_codes[individual_genotypes[ip[1]]]] }.each{|r| counts[r[0]][r[1]]+=1}

        return counts
      end

      # Individual and genotype_code id's related to variation
      # @returns
      # Example:
      # [[1,2],[2,3],[<individual_id>,<genotype_code_id>]]
      def individual_genotypes
        @individual_genotypes||=compressed_genotype_vars.map{|cgv| cgv.unpacked_genotypes }.flatten(1).to_h
      end

      def individual_genotype_ids
        individual_genotypes.keys
      end

      # IndividualPopulations from individual_genotypes
      # @returns [IndividualPopulation,IndividualPopulation,...]
      def individual_populations
        IndividualPopulation.where(individual_id: individual_genotype_ids)
      end

      def genotype_code_ids
        @genotype_code_ids||=individual_genotypes.values.uniq
      end

      # Unique genotype codes from individual_genotypes
      # @returns [<genotype_code_id>=>'G|C',2=>'A|A']
      def genotype_codes
        @genotype_codes||=GenotypeCode.genotypes_hash_for(genotype_code_ids)
      end

      # Find Variation by also using VariationSynonyms
      # @name: name of the variation
      # @return: [Variation]
      def self.find_by_name(name)
        v  = self.find_by(name: name)
        return v unless v.nil?
        vs = VariationSynonym.eager_load(:variation).find_by(name: name)
        return vs.variation unless vs.nil?
        nil
      end

      def self.find_all_by_name(name)
        v_ids = where(name: name).pluck(:variation_id)
        v_ids = variation_synonyms.where(name: name).pluck(:variation_id) if v_ids.nil?

        return nil if v_ids.nil?

        where(variation_id: v_ids).order(:name)
      end

      def genes
        variation_genenames.pluck(:gene_name)
      end

      def positions
        variation_features.includes(:seq_region).pluck('seq_region.name',:seq_region_start,:seq_region_end,:seq_region_strand).map{|r| Ensembl::Helpers::VariationPosition.new(r)}
      end

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

      def strand_name(id)
        case(id)
          when 1
            'forward'
          else
            'reverse'
        end
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
      # self.extend Ensembl::SearchByName

      belongs_to :short_name, foreign_key: 'short_name_attrib_id', class_name: 'Attrib'
      has_many :structural_variations

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

      scope :name_like, ->(name, search_type=:starts_with){
        at=self.arel_table

        if search_type == :ends_with
          where(at[:name].matches("%#{name}"))
        elsif search_type == :starts_with
          where(at[:name].matches("#{name}%"))
        else
          where(at[:name].matches("%#{name}%"))
        end

      }
    end
  end
end