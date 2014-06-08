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

module ImporterNew
  class ImporterNewDatabase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection CONFIG['db']['importer_new']
  end

  class Ragazzo < ImporterNewDatabase
    self.table_name = "ragazzo"

    belongs_to :gruppo, foreign_key: [:idgruppo, :idunitagruppo]
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

class Caricamento

  ## attenzioni da avere:
  ##
  ## clan duplicati in piu record
  ## clan internazionali mancanti

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

  def self.carica_routes(file_gemellaggi=CONFIG['files']['gemellaggi'])
    gemellaggi = CSV.read(file_gemellaggi, headers: true, col_sep: "\t")
    gemellaggi.each do |riga_gemellaggio|
      insert_gemellaggi(riga_gemellaggio)
    end   
  end


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

  def self.insert_route(record_gemellaggio)
    area = record_gemellaggio["Area"]
    nome = record_gemellaggio["Route"]
    numero = nome.gsub(/\D+/,'').to_i
    Route.where(name:   nome,
                numero: numero,
                area:   area).first_or_create
  end
  def self.insert_gemellaggi(record_gemellaggio)
    route = insert_route(record_gemellaggio)
    vclan = Vclan.where(nome: record_gemellaggio["gruppo_capo"], 
                        idunitagruppo: record_gemellaggio["unita_gruppo_capo"]).first
    if vclan
      gem = route.gemellaggios.where(vclan: vclan).first_or_initialize
      gem.ospitante = true if record_gemellaggio["livello ospite"] == '0'
      gem.save or puts gem.errors.inspect
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
  def assegna_idvclan
    self.idvclan = "#{self.idgruppo}-#{self.idunitagruppo}"
  end
end

