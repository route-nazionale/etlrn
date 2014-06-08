#!/bin/env ruby
# encoding: utf-8

# require 'rubygems'
# require 'bundler'
# Bundler.require


require 'awesome_print'
require 'mysql2'

require 'yaml'
require 'active_record'
require 'composite_primary_keys'
require 'csv'


CONFIG = YAML.load_file("config.yml") unless defined? CONFIG
EDDA_DB = CONFIG['db']['edda_test']

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
  end

  class Capoextra < ImporterNewDatabase
    self.table_name = "capoextra"
  end

  class Capolaboratorio < ImporterNewDatabase
    self.table_name = "capolaboratorio"
  end

  class Capooneteam < ImporterNewDatabase
    self.table_name = "oneteam"

    # alimentari is a TINYINT column
    # we just redefine the method here to return the value cast how we want it
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


### ORDINE DA SEGUIRE
##
## 1) caricamento vclan
## 2) caricamento gemellaggi
## 3) caricamento ragazzi


class Caricamento

  ## attenzioni da avere:
  ##
  ## clan duplicati in piu record
  ## clan internazionali mancanti
  ## 
  ## soluzione implementata usare il file gruppi_ww

  def self.carica_vclan(classe_gruppo=ImporterNew::Gruppo, 
                        ww_creation=true, 
                        file_gruppi_ww=CONFIG['files']['gruppi_ww'])
    

    classe_gruppo.all.each do |record_gruppo|
      insert_gruppo(record_gruppo)      
    end

    ## creazione clan internazionali

    if ww_creation
      gww = CSV.read(file_gruppi_ww, headers: true, col_sep: "\t")
      gww.each do |riga|
        record_gruppo = ImporterNew::Gruppo.new(riga.to_hash)
        insert_gruppo(record_gruppo)      
      end
    end

  end

  ## CARICAMENTO ROUTE MOBILI E GEMELLAGGI
  ## 
  ## crea se non esiste la route
  ## crea se non esiste il gemellaggio specificando se ospitante

  def self.carica_routes(file_gemellaggi=CONFIG['files']['gemellaggi'])
    gemellaggi = CSV.read(file_gemellaggi, headers: true, col_sep: "\t")
    gemellaggi.each do |riga_gemellaggio|
      insert_gemellaggi(riga_gemellaggio)
    end   
  end

  ## CARICAMENTO RAGAZZI


  def self.carica_ragazzi(classe_ragazzo=ImporterNew::Ragazzo,
                          ww_creation=false,
                          file_ragazzi_ww=CONFIG['files']['ragazzi_ww'])
    Raise "dati #{classe_ragazzo} non coerenti: i codicei censimento non sono univoci e/o completamente valorizzati" unless controllo_coerenza_ragazzi(classe_ragazzo)    
    classe_ragazzo.all.each do |record_ragazzo|
      import_ragazzo(record_ragazzo)
    end.size
  end
  
  def self.controllo_coerenza_ragazzi(classe_ragazzo)
    classe_ragazzo.pluck(:codicecensimento).uniq.compact.size == classe_ragazzo.count
  end

  def self.import_ragazzo(record_ragazzo)
    ragazzo = Human.where(codice_censimento: record_ragazzo.codicecensimento).first_or_initialize
    ragazzo.nome            = record_ragazzo.nome
    ragazzo.cognome         = record_ragazzo.cognome
    ragazzo.sesso           = record_ragazzo.sesso
    ragazzo.data_nascita    = record_ragazzo.datanascita
    ragazzo.eta             = record_ragazzo.eta
    ragazzo.idgruppo        = record_ragazzo.idgruppo
    ragazzo.idunitagruppo   = definizione_unita(record_ragazzo)
    
    ragazzo.vclan           = definizione_vclan(record_ragazzo)

    ragazzo.novizio         = record_ragazzo.novizio

    ragazzo.colazione              = record_ragazzo.ncolazione
    ragazzo.dieta_alimentare_id    = record_ragazzo.nalimentari

    ragazzo.el_intolleranze_alimentari = record_ragazzo.intolleranzealimentari
    ragazzo.el_allergie_alimentari     = record_ragazzo.allergiealimentari
    ragazzo.el_allergie_farmaci        = record_ragazzo.allergiefarmaci
    
    ragazzo.fisiche                = record_ragazzo.fisiche
    ragazzo.lis                    = record_ragazzo.lis
    ragazzo.psichiche              = record_ragazzo.psichiche
    ragazzo.sensoriali             = record_ragazzo.sensoriali

    ragazzo.patologie              = record_ragazzo.patologie

    ragazzo.stradadicoraggio1 = record_ragazzo.stradadicoraggio1
    ragazzo.stradadicoraggio2 = record_ragazzo.stradadicoraggio2
    ragazzo.stradadicoraggio3 = record_ragazzo.stradadicoraggio3
    ragazzo.stradadicoraggio4 = record_ragazzo.stradadicoraggio4
    ragazzo.stradadicoraggio5 = record_ragazzo.stradadicoraggio5

    ragazzo.rs    = true
    ragazzo.scout = true
    ragazzo.save


  end

  ## se idunitagruppo non è valorizzata si assume "T1"
  def self.definizione_unita(record_ragazzo)
    iduni = record_ragazzo.idunitagruppo
    if iduni.empty?
      "T1"
    else
      iduni
    end
  end

  def self.definizione_vclan(record_ragazzo)
    vclan = Vclan.where(idgruppo:      record_ragazzo.idgruppo,
                        idunitagruppo: definizione_unita(record_ragazzo)
                        ).first    
  end




  ## creazione VCLAN
  ##
  ## se il codice unita non è presente assegna "T1"
  ## TODO da spostare in Vclan la inizializzazione vera e propria

  def self.insert_gruppo(record_gruppo)
    if record_gruppo.unita.empty?
        record_gruppo.unita = "T1"
        puts "clan senza codice unita: #{record_gruppo.idgruppo} #{record_gruppo.nome} "
        ## TODO log aggiunte - necessita per extra agesci
      end

      vc = Vclan.where(     idgruppo: record_gruppo.idgruppo, 
                       idunitagruppo: record_gruppo.unita
                  ).first_or_initialize(
                    ordinale: record_gruppo.ordinale,
                    nome:     record_gruppo.nome,
                    regione:  record_gruppo.regione,
                    updated_at: Time.now,
                  )
      vc.assegna_idvclan
      vc.save
  end

  ## creazione ROUTE
  ##
  ## registra area e route
  ## TODO da spostare in Route la inizializzazione vera e propria

  def self.insert_route(record_gemellaggio)
    area = record_gemellaggio["Area"]
    nome = record_gemellaggio["Route"]
    numero = nome.gsub(/\D+/,'').to_i
    Route.where(name:   nome,
                numero: numero,
                area:   area).first_or_create
  end

  ## creazione GEMELLAGGIO
  ##
  ## recuperata o creata la route cerca il vclan
  ## se lo trova crea il gemellaggio memorizzando se il clan è ospitante
  ## 
  ## se non lo trova log di errore sulla riga
  ## 
  ## TODO da spostare in Vclan metodo di ricerca pulito

  def self.insert_gemellaggi(record_gemellaggio)
    route = insert_route(record_gemellaggio)
    vclan = Vclan.where(nome: record_gemellaggio["gruppo_capo"], 
                        idunitagruppo: record_gemellaggio["unita_gruppo_capo"]).first
    if vclan
      gemel = route.gemellaggios.where(vclan: vclan).first_or_initialize
      ## livello ospite 0 è dell'ospitante 1-2-3 degli ospitati in base a file Intini
      gemel.ospitante = true if record_gemellaggio["livello ospite"] == '0'
      gemel.save or puts gemel.errors.inspect
    else
      ## TODO log
      puts "gemellaggio non caricabile: #{record_gemellaggio.to_hash}"  
    end


  end


  
end


class EddaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection EDDA_DB
end


class Human < EddaDatabase
  belongs_to :vclan
end

class Route < EddaDatabase
  has_many :gemellaggios
  has_many  :vclans, through: :gemellaggios
end

class Gemellaggio < EddaDatabase
  belongs_to :route
  belongs_to :vclan
end

class Vclan < EddaDatabase
  has_many :gemellaggios
  has_many :humen


  def assegna_idvclan
    self.idvclan = "#{self.idgruppo}-#{self.idunitagruppo}"
  end
end

