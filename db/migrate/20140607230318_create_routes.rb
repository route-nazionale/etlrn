class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.string      :name
      t.integer     :numero
      t.string      :area
      t.timestamps
    end
    add_index :routes, :name
    add_index :routes, :numero
  end
end
