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

    def hg_version
      @hg_version||='37'
    end

    def version
      @version||='75'
    end

    def species
      @species||='homo_sapiens'
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

  module SearchByName
    def search(name)
      table=self.arel_table
      self.where(table[:name].matches("%#{name}%"))
    end
  end

  # class BaseConnection < ActiveRecord::Base
  #   self.extend TableNameOverrides
  #   self.abstract_class = true
  # end

  # module Core
  #   class Connection < ActiveRecord::Base
  #     self.extend TableNameOverrides
  #
  #     self.abstract_class = true
  #
  #     self.establish_connection :adapter  => "mysql2",
  #     :host     => Ensembl.host,
  #     :username => Ensembl.username,
  #     :password => Ensembl.password,
  #     :database => Ensembl.species+'_core_'+Ensembl.version+'_'+Ensembl.hg_version,
  #     :reconnect => true
  #
  #   end
  #
  #   class ModelBase < Connection
  #     self.extend PrimaryKeyOverrides
  #
  #     self.abstract_class = true
  #   end
  # end
  #
  # module Variation
  #   class Connection < ActiveRecord::Base
  #     self.extend TableNameOverrides
  #
  #     self.abstract_class = true
  #
  #     self.establish_connection :adapter  => "mysql2",
  #                               :host     => Ensembl.host,
  #                               :username => Ensembl.username,
  #                               :password => Ensembl.password,
  #                               :database => Ensembl.species+'_variation_'+Ensembl.version+'_'+Ensembl.hg_version,
  #                               :reconnect => true
  #
  #   end
  #
  #   class ModelBase < Connection
  #     self.extend PrimaryKeyOverrides
  #
  #     self.abstract_class = true
  #   end
  # end

end

require File.dirname(__FILE__) + '/ensembl/core/activerecord.rb'
require File.dirname(__FILE__) + '/ensembl/variation/activerecord.rb'
