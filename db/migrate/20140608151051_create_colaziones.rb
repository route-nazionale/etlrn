class CreateColaziones < ActiveRecord::Migration
  def change
    create_table :colaziones do |t|
      t.integer :kkey
      t.string :name
      t.timestamps
    end
  end
end
