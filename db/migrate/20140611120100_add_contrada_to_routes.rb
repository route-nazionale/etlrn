class AddContradaToRoutes < ActiveRecord::Migration
  def change
    add_column :routes, :contrada_id, :integer
    add_index :routes, [:contrada_id]
    add_index :routes, [:contrada_id, :quartiere]
  end
end
