class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.integer     :id
      t.string      :name
      t.integer     :numero
      t.datetime    :updated_at
      t.datetime    :created_at
    end
    add_index :vclans, :id
    add_index :vclans, :name
    add_index :vclans, :numero
  end
end
