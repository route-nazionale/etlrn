class AddVincoliToContradas < ActiveRecord::Migration
  def change
    add_column :contradas, :vincolo_tende, :integer
    add_column :contradas, :vincolo_persone, :integer
  end
end
