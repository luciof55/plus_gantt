# plus_gantt

Plugin for Redmine wich render a project gantt, adding a control date in order to visualize the expected ratio. Also calculate automatically issue due date.

When a issue is created or updated, the plugin calcualte and update the issue due date, based on start date, estimated hours and hours per day configuration. Hollydays are included in the calculation, if they are presents. Also bulk updates and create relantionship triggers due date calculation.

You can create a custom field, named “asignacion” at issue level, user level or project level. The plugin will take the value in that order, if none are present use the hours per day configuration (default is 8hs per day).

Installation notes

Attention This plugin extends core function

Download zip and go to Redmine plugins folder and unzip the plugin Or go to Redmine plugins folder and run “git clone github.com/luciof55/ganttplus.git” Then enable the plugin “Administration->Plugins” for projects
