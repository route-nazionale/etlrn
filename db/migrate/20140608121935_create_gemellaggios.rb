class CreateGemellaggios < ActiveRecord::Migration
  def change
    create_table :gemellaggios do |t|
      t.references :route
      t.references :vclan
      t.boolean    :ospitante, default: false
      t.timestamps
    end
  end
end
