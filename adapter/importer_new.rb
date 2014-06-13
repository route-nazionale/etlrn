
module ImporterNew
  class ImporterNewDatabase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection CONFIG['db']['importer_new']
  end

  class Ragazzo < ImporterNewDatabase
    self.table_name = "ragazzo"

    belongs_to :gruppo, foreign_key: [:idgruppo, :idunitagruppo]


    def ncolazione
      self.attributes_before_type_cast['colazione'].to_i
    end
    def nalimentari
      self.attributes_before_type_cast['alimentari'].to_i
    end
  end


  class Capo < ImporterNewDatabase
    self.table_name = "capo"


    def ncolazione
      self.attributes_before_type_cast['colazione'].to_i
    end
    def nalimentari
      self.attributes_before_type_cast['alimentari'].to_i
    end
  end

  class Capoextra < ImporterNewDatabase
    self.table_name = "capoextra"

    def ncolazione
      self.attributes_before_type_cast['colazione'].to_i
    end
    def nalimentari
      self.attributes_before_type_cast['alimentari'].to_i
    end
  end

  class Capolaboratorio < ImporterNewDatabase
    self.table_name = "capolaboratorio"

    def ncolazione
      self.attributes_before_type_cast['colazione'].to_i
    end
    def nalimentari
      self.attributes_before_type_cast['alimentari'].to_i
    end
  end

  class Capooneteam < ImporterNewDatabase
    self.table_name = "oneteam"

    # alimentari is a TINYINT column
    # we just redefine the method here to return the value cast how we want it

    def ncolazione
      self.attributes_before_type_cast['colazione'].to_i
    end
    def nalimentari
      self.attributes_before_type_cast['alimentari'].to_i
    end
  end

  class Gruppo < ImporterNewDatabase
    self.table_name = "gruppi"
    self.primary_keys = :idgruppo, :unita
    has_many :ragazzi, class_name: 'Ragazzo', foreign_key: [:idgruppo, :idunitagruppo]
    has_many :capi, class_name:    'Capo', foreign_key: [:idgruppo, :idunitagruppo]

    def ordinale
      idgruppo.gsub(/\D+/,'')
    end
  end
end