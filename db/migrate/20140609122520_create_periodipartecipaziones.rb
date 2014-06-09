class CreatePeriodipartecipaziones < ActiveRecord::Migration
  def change
    create_table :periodipartecipaziones do |t|
      t.integer :kkey
      t.string  :description
      t.integer :from_day
      t.integer :to_day
      t.integer :from_meal
      t.integer :to_meal
      t.integer :ruolo
      t.timestamps
    end
    add_index :periodipartecipaziones, [:kkey, :ruolo]
  end
end
