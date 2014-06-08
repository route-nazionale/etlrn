class CreateVclans < ActiveRecord::Migration
  def change
    create_table :vclans do |t|
      t.integer     :id
      t.string      :idvclan
      t.string      :idgruppo
      t.string      :idunitagruppo
      t.string      :ordinale
      t.string      :nome
      t.string      :regione
      t.datetime    :updated_at
      t.datetime    :created_at
    end
    add_index :vclans, :id
    add_index :vclans, :idvclan
    add_index :vclans, [:idgruppo, :idunitagruppo]
  end
end
