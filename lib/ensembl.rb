require "ensembl/version"
require 'active_record'
require 'yaml'
require 'active_support/core_ext'

# Load configuration from database.yml
ActiveRecord::Base.configurations = YAML::load(IO.read('config/database.yml'))

module Ensembl

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

  module AttributeLike
    def a_like(attribute, string)
      table=self.arel_table
      self.where(table[attribute].matches("%#{string}%"))
    end
  end

end

require File.dirname(__FILE__) + '/ensembl/core/activerecord.rb'
require File.dirname(__FILE__) + '/ensembl/variation/activerecord.rb'
require File.dirname(__FILE__) + '/ensembl/variation/tableless.rb'
