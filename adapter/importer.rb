module Importer
  class ImporterDatabase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection CONFIG['db']['importer']
  end

  class Ragazzo < ImporterDatabase
    self.table_name = "ragazzo"

    belongs_to :gruppo, foreign_key: [:idgruppo, :idunitagruppo]
  end


  class Capo < ImporterDatabase
    self.table_name = "capo"
  end

  class Quartiere < ImporterDatabase
    self.table_name = "quartiere"
  end

  class Capoextra < ImporterDatabase
    self.table_name = "capoextra"
  end

  class Capolaboratorio < ImporterDatabase
    self.table_name = "capolaboratorio"
  end

  class Capooneteam < ImporterDatabase
    self.table_name = "oneteam"

    # alimentari is a TINYINT column
    # we just redefine the method here to return the value cast how we want it
    def nalimentari
      self.attributes_before_type_cast['alimentari'].to_i
    end
  end

  class Gruppo < ImporterDatabase
    self.table_name = "gruppi"
    self.primary_keys = :idgruppo, :unita
    has_many :ragazzi, class_name: 'Ragazzo', foreign_key: [:idgruppo, :idunitagruppo]
    has_many :capi, class_name:    'Capo', foreign_key: [:idgruppo, :idunitagruppo]

    def ordinale
      idgruppo.gsub(/\D+/,'')
    end
  end
end