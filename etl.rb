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

    SPAZIO_CODICE_CLAN = 4
    SPAZIO_CODICE_IDENTIFICATIVO = 6



## MODULO DI INTERFACCIA CON IMPORTER
require './adapter/importer'

## MODULO DI INTERFACCIA CON IMPORTER_NEW
require './adapter/importer_new'

## MODULO DI INTERFACCIA CON CAMST
require './adapter/camst'


### ORDINE DA SEGUIRE
##
## 0) popolamento descrittori
## 1) caricamento vclan
## 2) caricamento gemellaggi
## 3) caricamento ragazzi
## 4) caricamento capi rs
## 5) posizionamento base route



class Caricamento

  ## POPOLAMENTO TABELLE RIFERIMENTO

  def self.popolamento_descrittori(file_popolamento=CONFIG['files']['descrittori'])
    descrittori = YAML.load_file(file_popolamento)
    descrittori["dietabase"].each{|dieta|    Dietabase.where(dieta).first_or_create}
    descrittori["colaziones"].each{|dieta|   Colazione.where(dieta).first_or_create}
    descrittori["chiefroles"].each{|dieta|   Chiefrole.where(dieta).first_or_create}
    descrittori["periodipartecipazione"].each{|dieta|   Periodipartecipazione.where(dieta).first_or_create}
    ##TODO caricamento quartieri e contrade

    # quartieri = CSV.read(CONFIG["files"]["quartieri"], headers: true)
    # quartieri.map{|q| d = District.find(q["num"]); d.update_attributes(numero: q["num"], vincolo_tende: q["tende"], vincolo_persone: q["vincolo_persone"], color: q["colore"])}
    # contrade = CSV.read(CONFIG["files"]["contrade"], headers: true)
    # contrade.map{|q| c = Contrada.where(numero: q["numero"], district_id: q["quartire"]).first; c.update_attributes(vincolo_tende: q["tende"], vincolo_persone: q["vincolo_persone"]) if c}

  end


  ##CARICAMNETO GRUPPI E CLAN
  ##
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
    raise "dati #{classe_ragazzo} non coerenti: i codici censimento non sono univoci e/o completamente valorizzati" unless controllo_coerenza_ragazzi(classe_ragazzo)
    classe_ragazzo.all.each do |record_ragazzo|
      import_ragazzo(record_ragazzo)
    end.size
  end

  ## CARICAMENTO CAPI RS

  def self.carica_capi_rs(classe_capo=ImporterNew::Capo,
                          ww_creation=false)
    raise "dati #{classe_capo} non coerenti: i codici censimento non sono univoci e/o completamente valorizzati" unless controllo_coerenza_capi_agesci(classe_capo)
    classe_capo.all.each do |record_capo|
      importa_capo(record_capo)
    end.size
  end

  ## CARICAMENTO CAPI ONETEAM

  def self.carica_capi_oneteam(classe_capo=ImporterNew::Capooneteam)
    Vclan.where(idvclan: 'ONETEAM-T1').first_or_create(idgruppo: 'ONETEAM', idunitagruppo: 'T1', ordinale: 'ONETEAM', nome: "ONETEAM", regione: 'SER')

    raise "dati #{classe_capo} non coerenti: i codici censimento non sono univoci e/o completamente valorizzati" unless controllo_coerenza_capi_agesci(classe_capo)
    classe_capo.all.each do |record_capo|
      importa_capo_oneteam(record_capo)
    end.size
  end

  ## CARICAMENTO CAPI EXTRA


  def self.carica_capi_extra(classe_capo=ImporterNew::Capoextra)
    Vclan.where(idvclan: 'EXTRA-T1').first_or_create(idgruppo: 'EXTRA', idunitagruppo: 'T1', ordinale: 'EXTRA', nome: "EXTRA", regione: 'SER')

    raise "dati #{classe_capo} non coerenti: i codici censimento non sono univoci e/o completamente valorizzati" unless controllo_coerenza_capi_agesci(classe_capo)
    classe_capo.all.each do |record_capo|
      importa_capo_extra(record_capo)
    end.size
  end

  ## CARICAMENTO CAPI LABORATORI

  def self.carica_capi_lab(classe_capo=ImporterNew::Capolaboratorio)
    Vclan.where(idvclan: 'LAB-T1').first_or_create(idgruppo: 'LAB', idunitagruppo: 'T1', ordinale: 'LAB', nome: "LABORATORI", regione: 'SER')

    raise "dati #{classe_capo} non coerenti: i codici censimento non sono univoci e/o completamente valorizzati" unless controllo_coerenza_capi_agesci(classe_capo)
    classe_capo.all.each do |record_capo|
      importa_capo_lab(record_capo)
    end.size
  end

  ##### STRUMENTI
  def self.codici_duplicati
  ["657986", "658054", "955534", "629147", "831387"]
  end
  def self.controllo_coerenza_capi_agesci(classe_capo)
    #classe_capo.pluck(:codicecensimento).uniq.compact.size == classe_capo.count
    a = (classe_capo.pluck(:codicecensimento).uniq.compact - codici_duplicati).size
    b = classe_capo.where("codicecensimento not in (? )", codici_duplicati ).count
    a == b
  end



  def self.importa_capo_lab(record_capo)

    # se presente
    if capo = Human.where(codice_censimento: record_capo.codicecensimento).first
      capo.update_attributes(lab: true)
    else
      capo = Human.create(codice_censimento: record_capo.codicecensimento,
                          rs: false,
                          scout: true,
                          lab: true   )

      capo.nome            = record_capo[:nome]
      capo.cognome         = record_capo[:cognome]
      capo.sesso           = record_capo[:sesso]
      capo.data_nascita    = record_capo[:datanascita]
      capo.eta             = record_capo[:eta]
      capo.idgruppo        = 'LAB'
      capo.idunitagruppo   = 'T1'
      capo.vclan           = Vclan.where(idvclan: 'LAB-T1').first

      capo.ruolo_id               = record_capo[:ruolo]
      capo.colazione              = record_capo.ncolazione
      capo.dieta_alimentare_id    = record_capo.nalimentari

      capo.el_intolleranze_alimentari = record_capo[:intolleranzealimentari]
      capo.el_allergie_alimentari     = record_capo[:allergiealimentari]
      capo.el_allergie_farmaci        = record_capo[:allergiefarmaci]

      capo.fisiche                = record_capo[:fisiche]
      capo.lis                    = record_capo[:lis]
      capo.psichiche              = record_capo[:psichiche]
      capo.sensoriali             = record_capo[:sensoriali]

      capo.patologie              = record_capo[:patologie]
      capo.pagato                 = record_capo[:pagamento] or record_capo[:pagato]
      capo.mod_pagamento_id       = record_capo[:modpagamento]


      capo.email                  = record_capo[:email]
      capo.indirizzo              = record_capo[:indirizzo]
      capo.cap                    = record_capo[:cap]
      capo.citta                  = record_capo[:citta]
      capo.provincia              = record_capo[:provincia]
      capo.cellulare              = record_capo[:cellulare]
      capo.abitazione             = record_capo[:abitazione]

      capo.save
    end
    #capo.periodo partecipazione_id = definizione_periodo_partecipazione(record_capo, capo.periodo_partecipazione_id)
  end


  def self.importa_capo_extra(record_capo)

    # se presente
    if capo = Human.where(codice_censimento: record_capo.codicecensimento).first
      capo.update_attributes(extra: true)
    else
      capo = Human.create(codice_censimento: record_capo.codicecensimento,
                          rs: false,
                          scout: true,
                          extra: true   )

      capo.nome            = record_capo[:nome]
      capo.cognome         = record_capo[:cognome]
      capo.sesso           = record_capo[:sesso]
      capo.data_nascita    = record_capo[:datanascita]
      capo.eta             = record_capo[:eta]
      capo.idgruppo        = 'EXTRA'
      capo.idunitagruppo   = 'T1'
      capo.vclan           = Vclan.where(idvclan: 'EXTRA-T1').first

      capo.ruolo_id               = record_capo[:ruolo]
      capo.colazione              = record_capo.ncolazione
      capo.dieta_alimentare_id    = record_capo.nalimentari

      capo.el_intolleranze_alimentari = record_capo[:intolleranzealimentari]
      capo.el_allergie_alimentari     = record_capo[:allergiealimentari]
      capo.el_allergie_farmaci        = record_capo[:allergiefarmaci]

      capo.fisiche                = record_capo[:fisiche]
      capo.lis                    = record_capo[:lis]
      capo.psichiche              = record_capo[:psichiche]
      capo.sensoriali             = record_capo[:sensoriali]

      capo.patologie              = record_capo[:patologie]
      capo.pagato                 = record_capo[:pagamento] or record_capo[:pagato]
      capo.mod_pagamento_id       = record_capo[:modpagamento]


      capo.email                  = record_capo[:email]
      capo.indirizzo              = record_capo[:indirizzo]
      capo.cap                    = record_capo[:cap]
      capo.citta                  = record_capo[:citta]
      capo.provincia              = record_capo[:provincia]
      capo.cellulare              = record_capo[:cellulare]
      capo.abitazione             = record_capo[:abitazione]

      capo.save
    end
    #capo.periodo partecipazione_id = definizione_periodo_partecipazione(record_capo, capo.periodo_partecipazione_id)
  end


  def self.importa_capo_oneteam(record_capo)
    capo = Human.where(
                        codice_censimento: record_capo.codicecensimento
                      ).first_or_create

    capo.update_attributes(
                                        rs: false,
                                        scout: true,
                                        oneteam: true
                                        )
    capo.nome            = record_capo[:nome]
    capo.cognome         = record_capo[:cognome]
    capo.sesso           = record_capo[:sesso]
    capo.data_nascita    = record_capo[:datanascita]
    capo.eta             = record_capo[:eta]
    capo.idgruppo        = 'ONETEAM'
    capo.idunitagruppo   = 'T1'
    capo.vclan           = Vclan.where(idvclan: 'ONETEAM-T1').first

    #capo.periodo partecipazione_id = definizione_periodo_partecipazione(record_capo, capo.periodo_partecipazione_id)
    capo.ruolo_id                  = record_capo[:ruolo]

    capo.colazione              = record_capo.ncolazione
    capo.dieta_alimentare_id    = record_capo.nalimentari

    capo.el_intolleranze_alimentari = record_capo[:intolleranzealimentari]
    capo.el_allergie_alimentari     = record_capo[:allergiealimentari]
    capo.el_allergie_farmaci        = record_capo[:allergiefarmaci]

    capo.fisiche                = record_capo[:fisiche]
    capo.lis                    = record_capo[:lis]
    capo.psichiche              = record_capo[:psichiche]
    capo.sensoriali             = record_capo[:sensoriali]

    capo.patologie              = record_capo[:patologie]
    capo.pagato                 = record_capo[:pagamento] or record_capo[:pagato]
    capo.mod_pagamento_id       = record_capo[:modpagamento]


    capo.email                  = record_capo[:email]
    capo.indirizzo              = record_capo[:indirizzo]
    capo.cap                    = record_capo[:cap]
    capo.citta                  = record_capo[:citta]
    capo.provincia              = record_capo[:provincia]
    capo.cellulare              = record_capo[:cellulare]
    capo.abitazione             = record_capo[:abitazione]

    capo.save
  end


  def self.importa_capo(record_capo)
    capo = Human.where(
                        codice_censimento: record_capo.codicecensimento
                      ).first_or_create(
                                        rs: false,
                                        scout: true
                                        )
    capo.nome            = record_capo[:nome]
    capo.cognome         = record_capo[:cognome]
    capo.sesso           = record_capo[:sesso]
    capo.data_nascita    = record_capo[:datanascita]
    capo.eta             = record_capo[:eta]
    capo.idgruppo        = record_capo[:idgruppo]
    capo.idunitagruppo   = definizione_unita(record_capo)
    capo.vclan           = definizione_vclan(record_capo)

    capo.ruolo_id                  = record_capo[:ruolo]

    capo.colazione              = record_capo.ncolazione
    capo.dieta_alimentare_id    = record_capo.nalimentari

    capo.el_intolleranze_alimentari = record_capo[:intolleranzealimentari]
    capo.el_allergie_alimentari     = record_capo[:allergiealimentari]
    capo.el_allergie_farmaci        = record_capo[:allergiefarmaci]

    capo.fisiche                = record_capo[:fisiche]
    capo.lis                    = record_capo[:lis]
    capo.psichiche              = record_capo[:psichiche]
    capo.sensoriali             = record_capo[:sensoriali]

    capo.patologie              = record_capo[:patologie]


    capo.email                  = record_capo[:email]
    capo.indirizzo              = record_capo[:indirizzo]
    capo.cap                    = record_capo[:cap]
    capo.citta                  = record_capo[:citta]
    capo.provincia              = record_capo[:provincia]
    capo.cellulare              = record_capo[:cellulare]
    capo.abitazione             = record_capo[:abitazione]

    capo.save
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
  def self.definizione_unita(record)
    iduni = record.idunitagruppo
    if iduni.empty?
      case record.class
      when ImporterNew::Ragazzo then "T1"
      when Importer::Ragazzo then "T1"
      when ImporterNew::Capo then ""
      else
        ""
      end
    else
      iduni
    end
  end

  ## se idunitagruppo non è valorizzata si assume "T1"
  def self.definizione_periodo_partecipazione(record, actual_value)
    periodo = record.periodopartecipazione

    case record.class
    when ImporterNew::Ragazzo then 1
    when Importer::Ragazzo then 1
    when ImporterNew::Capo then 1
    when ImporterNew::Capooneteam     then (actual_value.to_i + (periodo.to_i * 10))
    when ImporterNew::Capolaboratorio then (actual_value.to_i + (periodo.to_i * 100))
    when ImporterNew::Capoextra       then (actual_value.to_i + (periodo.to_i * 1000))
    else
      nil
    end
  end

  def self.definizione_vclan(record)
    vclan = Vclan.where(idgruppo:      record.idgruppo,
                        idunitagruppo: definizione_unita(record)
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

  def self.posiziona_route_base(file_vincoli=CONFIG["files"]["vincoli"])
    6.times{|i| District.where( name: "sottocampo #{i+1}").first_or_create}
    Importer::Quartiere.all.each{|i| r = Route.where(numero: i[:route]).first; r.quartiere = i[:quartiere]; r.save}.size
    vincoli = CSV.read(file_vincoli, headers: true, col_sep: "\t")
    vincoli.map{|i| Route.find(i["route"]).update_attributes(
                                                          quartiere: i["sc"],
                                                          quartiere_lock: true
                                                          )
                }

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

## Metodi per la suddivisione delle routes nei sottocampi

class Suddivisione

  # Fintanto che i quartieri non sono in equilibrio sposta route
  #
  # sceglie a route più numerosa
  # la sposta nel sottocampo più vuoto
  # controlla e se non a posto ripete

  ## solo equilibrio numero totale


  def self.riequilibria_route(range=800)
    while !District.in_equilibrio?(range)
      d_hash = District.hash_abitanti
      d_max = d_hash[d_hash.keys.max]
      d_min = d_hash[d_hash.keys.min]
      r = d_max.routes.non_vincolate.sample
      r.spostala!(d_min)
      puts "Route #{r.numero} from #{d_max.id} to #{d_min.id}\n"
      puts District.numeri_quartieri + "\n\n"
    end
  end

  # Fintanto che i quartieri non sono in equilibrio sposta route
  #
  # sceglie la contrada con il numero maggiore di persone in eccesso
  # e quindi un numero negativo di posti in eccesso
  # estraa a caso una route
  # e la sposta nel sottocampo con più posti liberi
  #
  # controlla e se non a posto ripete

  ## equilibrio basato su numero vincolato


  def self.riequilibria_route_vincolato(soglia=0)
    while !District.in_equilibrio_persone_generale?(soglia)
      c_hash = District.hash_margine_persone
      c_max = c_hash[c_hash.keys.max]
      c_min = c_hash[c_hash.keys.min]
      r = c_min.routes.non_vincolate.sample
      r.spostala!(c_max)
      puts "Route #{r.numero} from #{c_min.id} to #{c_max.id}\n"
      puts District.numeri_quartieri + "\n\n"
    end
  end


  # azzera le contrade di un sottocampo o di tutti
  # 1-5 scelta quartiere
  # 0 tutte
  #
  # popolamento casuale in 5 contrade

  def self.rigenera_contrade(quartiere=0)
    elenco_quartieri = District.scelta_quartiere(quartiere)

    elenco_quartieri.map(&:assegna_contrade)
  end

  # riequilibrio contrade in base ai vincoli persone presenti

  def self.riequilibria_contrade_vincolate(quartiere= 0, soglia=0)
    elenco_quartieri = District.scelta_quartiere(quartiere)

    elenco_quartieri.map{|i| i.riequilibria_contrade(soglia)}
  end

end



class EddaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection EDDA_DB
end


class District < EddaDatabase
  has_many :contradas
  has_many :routes, foreign_key: 'quartiere'
  has_many :gemellaggios, through: :routes
  has_many :vclans, through: :gemellaggios
  has_many :humen, through: :vclans

  scope :quartieri_ragazzi, ->{where(id: [1,2,3,4,5])}

  def abitanti
    self.humen.count
  end

  def self.array_abitanti
    quartieri_ragazzi.map(&:abitanti)
  end

  def self.hash_abitanti
    result = {}
    quartieri_ragazzi.map{|i| result[i.abitanti] = i}
    result
  end

  def self.hash_margine_persone
    result = {}
    quartieri_ragazzi.map{|i| result[i.margine_persone] = i}
    result
  end

  def hash_margine_persone_contrade
    result = {}
    contradas.map{|i| result[i.margine_persone] = i}
    result
  end

  def self.in_equilibrio?(range=100)
    sit = District.array_abitanti
    sit.max - sit.min < range
  end

  # > 0 ci sono posti sufficienti
  # = 0 ci sono posti giusti
  # < 0 ci sono posti in meno
  def margine_persone
    vincolo_persone - abitanti
  end

  def in_equilibrio_persone?(soglia=0)
    margine_persone >= soglia
  end

  def self.in_equilibrio_persone_generale?(soglia=0)
    quartieri_ragazzi.map{|d| d.in_equilibrio_persone?}.all?
  end

  def in_equilibrio_persone_contrade?(soglia=0)
    contradas.map{|c| c.in_equilibrio?(soglia)}.all?
  end

  def self.numeri_quartieri(uni="\t")
    array_abitanti.join(uni)
  end

  # restituisce un array di quartieri

  def self.scelta_quartiere(quartiere)

    raise "scegliere un quartiere 1-5 o 0 per tutti" unless (0..5).include? quartiere

    case quartiere
    when 0 then District.quartieri_ragazzi.all
    else
      [District.find(quartiere)]
    end
  end

  def genera_contrade
    (1..5).each do |i|
      self.contradas.where(numero: i, name: "contrada Q#{self.id}-C#{i}").first_or_create
    end
  end

  def riequilibria_contrade(range)
    Contrada.riequilibria(self, range)
  end

  def assegna_contrade
    elenco_routes = self.routes
    elenco_routes.each_with_index do |r,i|
      r.assegna_contrada((i % 5) + 1)
    end
  end

  def self.situazione
    situa = {RN: {
                  tot:{
                    tot: Human.count,
                    tot_capi: Human.capi.count,
                    tot_rs: Human.rs.count,
                  },
                  capi:{

                  },
                  rs:{
                  },
                  sdc:
                  {
                    sc1:    Human.sc1.count,
                    sc2:    Human.sc2.count,
                    sc3:    Human.sc3.count,
                    sc4:    Human.sc4.count,
                    sc5:    Human.sc5.count,
                  }

                }
            }

    (1..5).map{ |i|
      d = District.find(i)
      situa[d.id]  = {
                      sc1: d.humen.sc1.count,
                      sc2: d.humen.sc2.count,
                      sc3: d.humen.sc3.count,
                      sc4: d.humen.sc4.count,
                      sc5: d.humen.sc5.count,
                    }
      situa[:RN][:tot][d.id] = d.humen.count
      situa[:RN][:capi][d.id] = d.humen.capi.count
      situa[:RN][:rs][d.id] = d.humen.rs.count
      }

    situa
  end

  def self.situazione_vincoli
    situa = {}
    quartieri_ragazzi.each do |q|
      situa[q.name] = [q.vincolo_persone, q.abitanti, q.margine_persone, q.in_equilibrio_persone?]
    end
    situa
  end
  def self.situazione_vincoli_contrade
    situa = {}
    quartieri_ragazzi.each do |q|
      situa[q.name] = q.situazione_vincoli_contrade
    end
    situa
  end
  def self.situazione_vincoli_contrade_saldo
    situa = {}
    quartieri_ragazzi.each do |q|
      situa[q.name] = q.situazione_vincoli_contrade_saldo
    end
    situa
  end

  def situazione_vincoli_contrade
    situa = {}
    contradas.each do |c|
      situa[c.name] = [c.vincolo_persone, c.abitanti, c.margine_persone, c.in_equilibrio_persone?, c.vclans.count, c.in_equilibrio_vett?]
    end
    situa
  end
  def situazione_vincoli_contrade_saldo

    contradas.map{|i| i.margine_persone}

  end

  def nome
    name
  end
end

class Contrada < EddaDatabase
  belongs_to :disctrict
  has_many   :routes, foreign_key: 'contrada_id'
  has_many   :gemellaggios, through: :routes
  has_many   :vclans, through: :routes
  has_many   :humen, through: :routes

  def abitanti
    humen.count
  end

  def vclan_presenti
    vclans.count
  end

  # > 0 ci sono posti sufficienti
  # = 0 ci sono posti giusti
  # < 0 ci sono posti in meno
  def margine_persone
    vincolo_persone - abitanti
  end

  def in_equilibrio_persone?(soglia=0)
     margine_persone >= soglia
  end

  def in_equilibrio?(soglia=0)
     margine_persone >= soglia
  end

  def in_equilibrio_vett?(vclans_max=80)
    vclan_presenti <= vclans_max
  end


  def self.riequilibria(quartiere, range)
    puts "analisi #{quartiere.numero}"

    while !quartiere.in_equilibrio_persone_contrade?(range)
      d_hash = quartiere.hash_margine_persone_contrade
      d_max = d_hash[d_hash.keys.max]
      d_min = d_hash[d_hash.keys.min]
      r = d_min.routes.non_vincolate.sample
      r.spostala_di_contrada!(d_max)
      puts "Route #{r.numero} from contrada #{d_min.id} to contrada #{d_max.id}\n"
      ap quartiere.situazione_vincoli_contrade
      puts  "\n\n"
    end
  end

end

class Route < EddaDatabase

  self.table_name='routes_test'

  scope :non_vincolate, ->{where(quartiere_lock: false)}

  belongs_to :district, foreign_key: 'quartiere'
  belongs_to :contrada, counter_cache: true

  has_many :gemellaggios
  has_many  :vclans, through: :gemellaggios
  has_many  :humen, through: :vclans

  def spostala(disctrict)
    self.quartiere = district.id
  end

  def spostala!(district)
    self.update_attributes(quartiere: district.id)
  end

  def spostala_di_contrada(district)
    self.update_attributes(contrada_id: district.id)
  end

  def spostala_di_contrada!(district)
    self.update_attributes(contrada_id: district.id)
  end

  def assegna_contrada(num=1)
    raise "è necessario il numero di una contrada da 1 a 5" unless (1..5).include? num

    self.contrada = self.district.contradas.where(numero: num).first
    self.save
  end
end

class Gemellaggio < EddaDatabase
  belongs_to :route
  delegate :district, to: :route, allow_nil: true
  belongs_to :vclan
end

class Vclan < EddaDatabase
  has_one :gemellaggio
  has_one :route, through: :gemellaggio
  has_one :district, through: :route
  has_many :humen

  def assegna_idvclan
    self.idvclan = "#{self.idgruppo}-#{self.idunitagruppo}"
  end
end

class Human < EddaDatabase
  belongs_to :periodipartecipazione, foreign_key: :periodo_partecipazione_id
  belongs_to :dietabase, foreign_key: :dieta_alimentare_id
  belongs_to :tipo_colazione, foreign_key: :colazione, class_name: 'Colazione', primary_key: :kkey

  belongs_to :vclan
  has_one :gemellaggio, through: :vclan
  has_one :route, through: :gemellaggio
  has_one :district, through: :route

  scope :rs,   ->{where(rs: true)}
  scope :capi, ->{where(capo: 1)}
  scope :extra, ->{where(extra: true)}
  #scope :capi, ->{where(rs: false, scout: true)}
  scope :oneteam, ->{where(oneteam:true)}

  scope :sc1, ->{where(stradadicoraggio1: true)}
  scope :sc2, ->{where(stradadicoraggio2: true)}
  scope :sc3, ->{where(stradadicoraggio3: true)}
  scope :sc4, ->{where(stradadicoraggio4: true)}
  scope :sc5, ->{where(stradadicoraggio5: true)}

  def genera_cu
    cu = ""
    lettere = scegli_lettere.to_s
    clan    = codice_clan.to_s
    identificativo = codice_identificativo.to_s
    cu = lettere + clan + identificativo

    raise "cu no valido" unless Human.cu_valido?(cu)

    return cu
  end

  def scegli_lettere
    coppia = ""

    if rs
      coppia = "AG"
    elsif capo == 1
      coppia = "AA"
    elsif extra == true
      coppia = "AQ"
    elsif oneteam == true
      coppia = "OT"
    elsif lab == true
      coppia = "AL"
    elsif idgruppo == "KINDER-T1"
      coppia = "KD"
    else
      raise "lettere non assegnata"
    end
    coppia
  end

  def codice_clan


    codice = vclan_id.to_s.rjust(SPAZIO_CODICE_CLAN, "0")

    raise "id clan troppo lungo" if codice.size > SPAZIO_CODICE_CLAN

    return codice
  end

  def codice_identificativo


    codice = id.to_s.rjust(SPAZIO_CODICE_IDENTIFICATIVO, "0")

    raise "id individuale troppo lungo" if codice.size > SPAZIO_CODICE_IDENTIFICATIVO

    return codice
  end

  def self.cu_valido?(cu)
    (cu.size == 12) and ( cu =~ /(AA|AG|AQ|OT|AL|KD)(\d{4})(\d{6})/ )
  end


end


class Topic < EddaDatabase
end

class Colazione < EddaDatabase
end

class Dietabase < EddaDatabase
  has_many :humen, foreign_key: :dieta_alimentare_id
end

class Colazione < EddaDatabase
end


class Chiefrole < EddaDatabase
end

class Event < EddaDatabase
end

class Periodipartecipazione < EddaDatabase
  has_many :humen, foreign_key: :periodo_partecipazione_id
  has_many :vclans, through: :humen
end



