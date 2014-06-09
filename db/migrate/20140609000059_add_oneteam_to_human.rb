class AddOneteamToHuman < ActiveRecord::Migration
  def change
    add_column :humen, :oneteam, :boolean, default: false
  end
end
