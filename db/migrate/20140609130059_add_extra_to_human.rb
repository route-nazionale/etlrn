class AddExtraToHuman < ActiveRecord::Migration
  def change
    add_column :humen, :extra, :boolean, default: false
    add_column :humen, :lab,   :boolean, default: false
  end
end
