class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :name
      t.date :date
      t.string :lat
      t.string :lng
      t.string :obhana_info_url
      t.string :obhana_register_url
      t.string :club
      t.string :homepage

      t.timestamps
    end
  end
end
