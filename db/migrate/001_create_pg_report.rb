class CreatePgReport < ActiveRecord::Migration
  def up
    create_table :pg_reports do |t|
      t.belongs_to :project, :index => true, :null => false
	  t.column :control_date, :date, :null => false
      t.column :budget, :float, :null => false
      t.column :end_date, :date, :null => false
      t.column :progress, :float, :null => false
      t.column :expected_progress, :float, :null => false
	  t.column :partial_budget, :float, :null => false
	  t.column :hours_consumed, :float, :null => false
	  t.column :hours_adjusted, :float, :null => false
	  t.column :progress_status, :float, :null => false
	  t.column :hours_status, :float, :null => false
	  t.column :hours_percent_diff, :float, :null => false
	  t.column :status, :integer, :null => false
    end
  end
end