class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :locate_lat
      t.string :locate_lon
      t.string :address

      t.timestamps
    end
  end
end
