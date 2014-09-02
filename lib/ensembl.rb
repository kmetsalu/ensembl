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

  # ConnectionPool implemented from:
  # http://www.lucasallan.com/2014/05/26/fixing-concurrency-issues-with-active-record-in-a-rack-application.html
  class ConnectionPooledBase < ActiveRecord::Base
    self.abstract_class = true

    singleton_class.send(:alias_method, :original_connection, :connection)

    def self.connection
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        conn
      end
    end
  end
end

require File.dirname(__FILE__) + '/ensembl/helpers/like_search.rb'
require File.dirname(__FILE__) + '/ensembl/core/activerecord.rb'
require File.dirname(__FILE__) + '/ensembl/helpers/variation_position.rb'
require File.dirname(__FILE__) + '/ensembl/variation/activerecord.rb'
require File.dirname(__FILE__) + '/ensembl/variation/tableless.rb'
