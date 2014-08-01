module Labcapi
  class LabcapiDatabase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection CONFIG['db']['labcapi']
  end

  class Quartiere < LabcapiDatabase
    self.table_name = "camp_districts"
    self.primary_keys = :code
    has_many :events, primary_key: :code, foreign_key: :district_id
  end


  class Assegnrs < LabcapiDatabase
    self.table_name = "ragazzi_assegnati"
  end

  class Assegncapo < LabcapiDatabase
    self.table_name = "subscriptions"
    self.primary_keys = :id

    belongs_to :turno, foreign_key: :event_happening_id_id, primary_key: :id
    belongs_to :capo, foreign_key: :scout_chief_id, primary_key: :id
  end

  class Capo < LabcapiDatabase
    self.table_name = "scout_chiefs"
    self.primary_keys = :id

    has_many :assegncapos,  foreign_key: :scout_chief_id

  end

  class Event < LabcapiDatabase
    self.table_name = "camp_events"

    belongs_to :quartiere, foreign_key: :district_id
    has_many :turnos, primary_key: :id, foreign_key: :event_id

    def self.sposta_rs(origine, destinazione)
      if (origine.class == destinazione.class) and (origine.class == Event)

        Assegnrs.where(turno1: origine.code).map{|i| i.turno1 = destinazione.code; i.save}
        Assegnrs.where(turno2: origine.code).map{|i| i.turno2 = destinazione.code; i.save}
        Assegnrs.where(turno3: origine.code).map{|i| i.turno3 = destinazione.code; i.save}

        origine.turnos.map(&:aggiorna_num_ragazzi!)
        destinazione.turnos.map(&:aggiorna_num_ragazzi!)
      else
        raise "origine e destinazione devo essere eventi"
      end
    end



    def self.sposta_capi(origine, destinazione)
      if (origine.class == destinazione.class) and (origine.class == Event)
        origine.turnos.map{|i| i.assegncapos.map{|a| h =  destinazione.turnos.where(timeslot_id: i.timeslot_id).first;
                                             a.event_happening_id = h.id;
                                             a.save}}

        origine.turnos.map(&:aggiorna_num_capi!)
        destinazione.turnos.map(&:aggiorna_num_capi!)
      else
        raise "origine e destinazione devo essere eventi"
      end
    end

  end

  class Turno < LabcapiDatabase
    self.table_name = "camp_eventhappenings"

    belongs_to :event, foreign_key: :event_id
    has_many :assegncapos, primary_key: :id, foreign_key: :event_happening_id
    #has_many :capi, class_name: 'Capo', primary_key: :id, foreign_key: :event_id

    scope :ven_mat, ->{where(timeslot_id: 1)}
    scope :ven_pom, ->{where(timeslot_id: 2)}
    scope :sab_mat, ->{where(timeslot_id: 3)}


    delegate :code, to: :event

    def ragazzi
      Assegnrs.where("turno#{self.timeslot_id} = ? ", self.code)
    end

    def aggiorna_num_ragazzi
      self.seats_n_boys = self.ragazzi.count
    end

    def aggiorna_num_capi
      self.seats_n_chiefs = self.assegncapos.count
    end

    def aggiorna_num_ragazzi!
      self.seats_n_boys = self.ragazzi.count
      self.save
    end

    def aggiorna_num_capi!
      self.seats_n_chiefs = self.assegncapos.count
      self.save
    end


  end


end
