class AddQuartiereToRoutes < ActiveRecord::Migration
  def change
    add_column :routes, :quartiere, :integer
  end
end
