require "ensembl/version"
require 'active_record'
require 'yaml'
require 'active_support/core_ext'

module Ensembl
  # Load configuration from database.yml
  ActiveRecord::Base.configurations = YAML::load(IO.read('config/database.yml'))

  module TableNameOverrides
    def table_name
      self.name.split('::').last.underscore || ''
    end
  end

  module PrimaryKeyOverrides
    def primary_key
      self.table_name + '_id'
    end
  end

  # module AttributeLike
  #   def a_like(attribute, string, search_type=:between)
  #     at=self.arel_table
  #     if search_type == :ends_with
  #       where(at[attribute].matches("%#{string}"))
  #     elsif search_type == :starts_with
  #       where(at[attribute].matches("#{string}%"))
  #     else
  #       where(at[attribute].matches("%#{string}%"))
  #     end
  #   end
  # end
end

require File.dirname(__FILE__) + '/ensembl/helpers/like_search.rb'
require File.dirname(__FILE__) + '/ensembl/core/activerecord.rb'
require File.dirname(__FILE__) + '/ensembl/helpers/variation_position.rb'
require File.dirname(__FILE__) + '/ensembl/variation/activerecord.rb'
require File.dirname(__FILE__) + '/ensembl/variation/tableless.rb'
