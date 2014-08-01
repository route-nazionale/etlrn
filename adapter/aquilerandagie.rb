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
    has_one    :salute, foreign_key: [:cu]
  end

  class Personali < AquilerandagieDatabase
    self.table_name = "humen_personali"
  end

  class Spalla < AquilerandagieDatabase
    self.table_name = "humen_spalla"
    self.primary_keys = :cu
  end

  class Abbspalla < AquilerandagieDatabase
    self.table_name = "capiSpallaAssegnati"
    self.primary_keys = :cu
  end

  class Salute < AquilerandagieDatabase
    self.table_name = "humen_health"
    belongs_to :human, foreign_key: [:cu]
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
