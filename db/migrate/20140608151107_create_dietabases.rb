class CreateDietabases < ActiveRecord::Migration
  def change
    create_table :dietabases do |t|
      t.integer :kkey
      t.string :name
      t.timestamps
    end
  end
end
