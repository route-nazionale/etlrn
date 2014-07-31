module Aquilerandagie
  class AquilerandagieDatabase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection CONFIG['db']['aquilerandagie']
  end



  class Ruolo < AquilerandagieDatabase
    self.table_name = "ruolopartecipante"
  end

  class Human < AquilerandagieDatabase
    self.table_name = "humen"
    belongs_to :gruppo, foreign_key: [:idgruppo, :idunitagruppo]
  end

  class Personali < AquilerandagieDatabase
    self.table_name = "humen_personali"
  end

  class Salute < AquilerandagieDatabase
    self.table_name = "humen_health"
  end

  class Scelta < AquilerandagieDatabase
    self.table_name = "humen_sceltestrada"
  end

  class Capolaboratorio < AquilerandagieDatabase
    self.table_name = "humen_laboratori"
  end

  class Laboratorio < AquilerandagieDatabase
    self.table_name = "laboratori"
  end

  class Tavola < AquilerandagieDatabase
    self.table_name = "tavolerotonde"
  end





  class Gruppo < AquilerandagieDatabase
    self.table_name = "gruppi"
    self.primary_keys = :idgruppo, :idunita

    has_many :humen, class_name: 'Human', foreign_key: [:idgruppo, :idunitagruppo]
  end
end