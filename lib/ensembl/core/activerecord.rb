module Ensembl
  module Core

    module StableIdHistory
      def previous_stable_ids
        StableIdEvent.where(new_stable_id: stable_id)
      end
    end

    class Connection < ActiveRecord::Base
      self.extend TableNameOverrides

      self.abstract_class = true

      self.establish_connection :adapter  => "mysql2",
                                :host     => Ensembl.host,
                                :username => Ensembl.username,
                                :password => Ensembl.password,
                                :database => Ensembl.species+'_core_'+Ensembl.version+'_'+Ensembl.hg_version,
                                :reconnect => true

    end

    class ModelBase < Connection
      self.extend PrimaryKeyOverrides

      self.abstract_class = true
    end

    class AltAllele < ModelBase
      belongs_to :gene
      belongs_to :alt_allele_group
    end

    class AltAlleleAttrib < ModelBase
      belongs_to :alt_allele
    end

    class AltAlleleGroup < ModelBase
      has_many :alt_alleles
    end

    # TODO: Verify that is working
    class Analysis < ModelBase
      has_one :analysis_description
    end

    class AnalysisDescription < Connection
      has_one :analysis
    end

    class AssociatedGroup < ModelBase
      has_many :associated_xrefs
    end

    class AssociatedXref < ModelBase
      belongs_to :object_xref
      belongs_to :xref
      belongs_to :source_xref, foreign_key: 'source_xref_id', class_name: 'Xref'
      belongs_to :associated_group
    end

    class AttribType < ModelBase
      has_many :seq_region_attrib
    end

    class Assembly < Connection
      self.primary_key = 'asm_seq_region_id'

      belongs_to :seq_region
    end

    class AssemblyException < ModelBase
      belongs_to :seq_region
      belongs_to :exc_seq_region, foreign_key: 'ex_seq_region_id', class_name: 'SeqRegion'
    end

    class CoordSystem < ModelBase
      has_many :data_files
    end

    class DataFile < ModelBase
      belongs_to :coord_system
    end

    class DensityFeature < ModelBase
      belongs_to :seq_region
      belongs_to :density_type
    end

    class DensityType < ModelBase
      has_many :density_features
    end

    class Ditag < ModelBase
      has_many :ditag_features
    end

    class DitagFeature < ModelBase
      belongs_to :ditag
      belongs_to :seq_region
      belongs_to :analysis
    end

    class Dna < Connection
      has_one :seq_region
    end

    class DnaAlignFeature < ModelBase
      belongs_to :seq_region
      belongs_to :analysis
      belongs_to :external_db
    end

    class DependentXref < ModelBase
      belongs_to :object_xref
      belongs_to :master, foreign_key: 'master_xref_id', class_name: 'Xref'
      belongs_to :dependent, foreign_key: 'dependent_xref_id', class_name: 'Xref'
    end

    class Exon < ModelBase
      belongs_to :seq_region

      has_many :exon_transcripts
      has_many :transcripts, through: :exon_transcript

    end

    class ExonTranscript < Connection
      belongs_to :exon
      belongs_to :transcript
    end

    class ExternalDb < ModelBase
      # FIXME: Hack because using type column in the database
      self.inheritance_column = ':_no_inheritance_column'

      has_many :seq_region_synonyms

      scope :with_seq_region_synonyms, -> { where.not(seq_regions_synonyms.nil?)}
    end

    class ExternalSynonym < Connection
      self.primary_key = 'xref_id'
    end

    class Gene < ModelBase
      include StableIdHistory

      belongs_to :analysis
      belongs_to :seq_region
      belongs_to :display_xref, foreign_key: 'display_xref_id', class_name: 'Xref'
      belongs_to :transcript, foreign_key: 'canonical_transcript_id', class_name: 'Transcript'

      has_many :gene_attribs
      has_many :attrib_types, through: :gene_attribs

      has_many :operon_transcript_genes
      has_many :operon_transcripts, through: :operon_transcript_genes

    end

    # FIXME: Set up relations with stable IDs
    class GeneArchive < Connection
      belongs_to :peptide_archive
      belongs_to :mapping_session
    end

    class GeneAttrib < ModelBase
      belongs_to :gene
      belongs_to :attrib_type
    end

    # TODO: Inspect relation with ObjectXref
    class IdentityXref < Connection
      self.primary_key = 'object_xref_id'
    end

    class Interpro < Connection

    end

    class IntronSupportingEvidence < ModelBase
      belongs_to :analysis
      belongs_to :seq_region

    end

    class GenomeStatistics < ModelBase

    end

    class Karyotype < ModelBase
      belongs_to :seq_region

    end

    class Map < ModelBase

    end

    class MappingSession < ModelBase
      has_many :stable_id_events
    end

    class MappingSet < ModelBase
      has_many :seq_region_mappings
    end

    class Marker < ModelBase
      has_many :marker_features
      has_many :marker_synonyms
      has_many :marker_map_locations
    end

    class MarkerFeature < ModelBase
      belongs_to :marker
      belongs_to :seq_region
      belongs_to :analysis
    end

    class MarkerMapLocation < Connection
      belongs_to :marker
      belongs_to :map
      belongs_to :marker_synonym
    end

    class MarkerSynonym < ModelBase
      belongs_to :marker
    end

    class Meta < ModelBase

    end

    class MetaCoord < Connection
      belongs_to :coord_system

    end

    class MiscAttrib < Connection
      belongs_to :misc_feature
      belongs_to :attrib_type
    end

    class MiscFeature < ModelBase
      belongs_to :seq_region

      has_many :misc_attrib
      has_many :misc_feature_misc_sets
      has_many :misc_sets, through: :misc_feature_misc_sets
    end

    class MiscFeatureMiscSet < Connection
      belongs_to :misc_feature
      belongs_to :misc_set
    end

    class MiscSet < ModelBase
      has_many :misc_feature_misc_sets
      has_many :misc_sets, through: :misc_feature_misc_sets
    end

    class ObjectXref < ModelBase
      belongs_to :xref
      belongs_to :analysis
    end

    class OntologyXref < ModelBase
      belongs_to :object_xref
      belongs_to :source, foreign_key: 'source_xref_id', class_name: 'Xref'
    end

    class Operon < ModelBase
      belongs_to :analysis
      belongs_to :seq_region
    end

    class OperonTranscript < ModelBase
      belongs_to :analysis
      belongs_to :seq_region
      belongs_to :operon

      has_many :operon_transcript_genes
      has_many :genes, through: :operon_transcript_genes
    end

    class PeptideArchive < ModelBase

    end

    class PredictionExon < ModelBase
      belongs_to :seq_region
      belongs_to :prediction_transcript
    end

    class PredictionTranscript < ModelBase
      belongs_to :seq_region
      belongs_to :analysis

      has_many :prediction_exons
    end

    class ProteinAlignFeature < ModelBase
      belongs_to :seq_region
      belongs_to :analysis
      belongs_to :external_db
    end

    class ProteinFeature < ModelBase
      belongs_to :translation
      belongs_to :analysis
    end

    class RepeatConsensus < ModelBase
      has_many :repeat_features
    end

    class RepeatFeature < ModelBase
      belongs_to :seq_region
      belongs_to :repeat_consensus
      belongs_to :analysis
    end

    class SeqRegion < ModelBase
      has_one :dna
      belongs_to :coord_system

      has_many :genes
      has_many :density_features
      has_many :prediction_exons
      has_many :prediction_transcripts
      has_many :repeat_features
      has_many :protein_align_features
      has_many :seq_region_attribs
      has_many :seq_region_synonyms
      has_many :simple_features
      has_many :splicing_events
      has_many :transcripts

    end

    class SeqRegionAttrib < Connection
      belongs_to :seq_region
      belongs_to :attrib_type
    end

    class SeqRegionMapping < Connection
      belongs_to :current, foreign_key: 'external_seq_region_id', class_name: 'SeqRegion'
      belongs_to :previous, foreign_key: 'internal_seq_region_id', class_name: 'SeqRegion'
      belongs_to :mapping_set
    end

    class SeqRegionSynonym < ModelBase
      belongs_to :seq_region
      belongs_to :external_db
    end

    class SimpleFeature < ModelBase
      belongs_to :seq_region
      belongs_to :analysis
    end

    class SplicingEvent < ModelBase
      belongs_to :seq_region
      belongs_to :attrib_type
      belongs_to :gene

      has_many :splicing_event_features
    end

    class SplicingEventFeature < ModelBase
      belongs_to :splicing_event
      belongs_to :exon
      belongs_to :transcript
    end

    class SplicingTranscriptPair < ModelBase
      belongs_to :splicing_event
      belongs_to :transcript1, foreign_key: 'transcript_id_1', class_name: 'Transcript'
      belongs_to :transcript2, foreign_key: 'transcript_id_2', class_name: 'Transcript'
    end

    # TODO: Fix inheritance
    class SupportingFeature < Connection
      belongs_to :exon

    end

    # FIXME: Setup stable ids
    class StableIdEvent < Connection
      # FIXME: Hack because using type column in the database
      self.inheritance_column = ':_no_inheritance_column'

      belongs_to :mapping_session
    end

    class Transcript < ModelBase
      include StableIdHistory

      belongs_to :gene
      belongs_to :analysis
      belongs_to :seq_region
      belongs_to :display_xref, foreign_key: 'display_xref_id', class_name: 'Xref'
      belongs_to :canonical_translation, foreign_key: 'canonical_translation_id', class_name: 'Translation'


      has_many :transcript_attribs
      has_many :translations

    end

    class TranscriptAttrib < Connection
      belongs_to :transcript
      belongs_to :attrib_type
    end

    # TODO: Fix inheritance
    class TranscriptSupportingFeature < Connection
      belongs_to :transcript
    end

    class TranscriptIntronSupportingEvidence < ModelBase
      belongs_to :transcript
      belongs_to :previous_exon
      belongs_to :next_exon
    end

    class Translation < ModelBase
      include StableIdHistory

      belongs_to :transcript
      belongs_to :start_exon, foreign_key: 'start_exon_id', class_name: 'Exon'
      belongs_to :end_exon, foreign_key: 'end_exon_id', class_name: 'Exon'

      has_many :protein_features
      has_many :translation_attribs
    end

    class TranslationAttrib < Connection
      belongs_to :translation
      belongs_to :attrib_type
    end

    # TODO: inspect ensembl_object_type and ensembl_id
    class UnmappedObject < ModelBase
      belongs_to :analysis
      belongs_to :external_db
      belongs_to :unmapped_reason
    end

    class UnmappedReason < ModelBase
      has_many :unmapped_objects
    end

    class Xref < ModelBase
      belongs_to :external_db

      has_many :object_xrefs

    end
  end
end