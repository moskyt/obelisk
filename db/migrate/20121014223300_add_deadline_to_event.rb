class AddDeadlineToEvent < ActiveRecord::Migration
  def change
    add_column :events, :deadline, :date
  end
end
