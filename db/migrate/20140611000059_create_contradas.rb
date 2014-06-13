class CreateContradas < ActiveRecord::Migration
  def change
    create_table :contradas do |t|
      t.integer :numero
      t.integer :district_id
      t.string :name
      t.integer :routes_count, default: 0
      t.timestamps
    end

    add_index :contradas, [:numero, :district_id]
    add_index :contradas, [:district_id]
  end
end
