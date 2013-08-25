class AddDeadlineExtendedToEvent < ActiveRecord::Migration
  def change
    add_column :events, :deadline_extended, :date
  end
end
