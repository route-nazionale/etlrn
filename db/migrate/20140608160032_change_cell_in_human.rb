class ChangeCellInHuman < ActiveRecord::Migration
  def change
    remove_column :humen,:cellulare
    add_column :humen, :cellulare, :string
  end
end
