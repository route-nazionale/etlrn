class CreateHumen < ActiveRecord::Migration
  def change
    create_table :humen do |t|
      t.integer     :id
      t.string      :cu
      t.integer     :codice_censimento
      t.string      :idgruppo
      t.string      :idunitagruppo
      t.integer     :vclan_id
      t.string      :nome
      t.string      :cognome
      t.string      :sesso
      
      t.date        :data_nascita
      t.integer     :eta
      
      t.integer     :periodo_partecipazione_id
      t.integer     :ruolo_id

      t.boolean     :novizio
      t.boolean     :scout
      t.boolean     :agesci
      t.boolean     :rs
      
      t.string      :email
      t.integer     :cellulare
      t.string      :abitazione
      t.string      :indirizzo
      t.string      :provincia
      t.string      :cap
      t.string      :citta
      
      t.integer     :pagato
      t.integer     :mod_pagamento_id
      
      t.integer     :colazione
      t.integer     :dieta_alimentare_id
      
      t.boolean     :intolleranze_alimentari
      t.string      :el_intolleranze_alimentari

      t.boolean     :allergie_alimentari
      t.string      :el_allergie_alimentari

      t.boolean     :allergie_farmaci
      t.string      :el_allergie_farmaci

      t.boolean     :fisiche
      t.boolean     :lis
      t.boolean     :psichiche
      t.boolean     :sensoriali
      t.string      :patologie

      t.boolean     :stradadicoraggio1
      t.boolean     :stradadicoraggio2
      t.boolean     :stradadicoraggio3
      t.boolean     :stradadicoraggio4
      t.boolean     :stradadicoraggio5

      t.datetime    :updated_at
      t.datetime    :created_at
    end
    add_index :humen, :id
    add_index :humen, :cu
    add_index :humen, :codice_censimento
    add_index :humen, :vclan_id
  end
end
