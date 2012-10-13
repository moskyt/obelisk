class AddRozpispokynyToEvent < ActiveRecord::Migration
  def change
    add_column :events, :rozpis_url, :string
    add_column :events, :pokyny_url, :string
  end
end
