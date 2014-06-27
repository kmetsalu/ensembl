require "ensembl/version"
require 'active_record'
require 'active_support/core_ext'

module Ensembl

  class << self

    attr_accessor :host, :port, :database, :username, :password

    def host
      @host||='ensembldb.ensembl.org'
    end

    def port
      @port||=3306
    end

    def username
      @username||='anonymous'
    end

    def password
      @password||=''
    end

    def database
      @database||='homo_sapiens_variation_75_37'
    end

  end

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

  class Connection < ActiveRecord::Base
    self.extend TableNameOverrides

    self.abstract_class = true

    self.establish_connection :adapter  => "mysql2",
                              :host     => Ensembl.host,
                              :username => Ensembl.username,
                              :password => Ensembl.password,
                              :database => Ensembl.database

  end

  class ModelBase < Connection
    self.extend PrimaryKeyOverrides

    self.abstract_class = true
  end
end

require File.dirname(__FILE__) + '/ensembl/variation/activerecord.rb'