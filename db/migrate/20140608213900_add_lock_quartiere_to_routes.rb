class AddLockQuartiereToRoutes < ActiveRecord::Migration
  def change
    add_column :routes, :quartiere_lock, :boolean, default: false
  end
end
