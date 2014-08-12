require 'active_record'
require 'activerecord-tableless'

module Ensembl
  module Variation

    class IndividualGenotype < ActiveRecord::Base
      has_no_table

      column :individual_id, :integer
      column :genotype_code_id, :integer
      column :allele, :string

      belongs_to :individual
      belongs_to :genotype_code

      delegate :individual_populations, to: :individual
      delegate :populations, to: :individual
    end

  end
end