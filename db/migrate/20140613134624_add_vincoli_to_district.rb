class AddVincoliToDistrict < ActiveRecord::Migration
  def change
    add_column :districts, :numero, :integer
    add_column :districts, :vincolo_tende, :integer
    add_column :districts, :vincolo_persone, :integer
  end
end
