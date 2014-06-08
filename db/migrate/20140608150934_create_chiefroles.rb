class CreateChiefroles < ActiveRecord::Migration
  def change
    create_table :chiefroles do |t|
      t.integer :kkey
      t.string :description
      t.timestamps
    end
  end
end
