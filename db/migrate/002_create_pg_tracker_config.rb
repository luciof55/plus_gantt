class CreatePgTrackerConfig < ActiveRecord::Migration
  def change
    create_table :pg_tracker_configs do |t|
      t.belongs_to :tracker, :index => true, :null => false
	  t.belongs_to :project, :index => true, :null => true
	  t.column :allow_time_log, :int, :null => false
    end
	
	add_foreign_key :pg_tracker_configs, :trackers, {:name => 'fk_tracker_config_tracker'}
	add_foreign_key :pg_tracker_configs, :projects , {:name => 'fk_tracker_config_project'}
	
	add_index :pg_tracker_configs, [:tracker_id, :project_id], unique: true
  end
end