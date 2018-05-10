# Plus Gantt


[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/plus_gantt)

[![Follow on Linkedin](https://aib.msu.edu/graphics/linked_in.png)](https://www.linkedin.com/in/lucioferrero/)
[![Follow on Twiter](https://aib.msu.edu/graphics/twitter_logo.png)](https://twitter.com/luciof55/)

**Plugin for Redmine wich render a project gantt, adding a control date in order to visualize the expected ratio. Also calculate automatically issue due date.**

## Gantt:

In order to see the plugin features, projets and issues must have a start date, a due date and a estimated time configured.

Go to a especific project, then click on "Plus Gantt" item menu. It will be show the project gantt. At this point there is no diference between the original Redmine Gantt. But you will see the actual progess and the expected progress if at least one issue is present.

The control date will be set to current date, you can change the value to another date, change the other options (months from, start month) and then click the button "Apply". Then the expected progress will change based on the new value of the control date.

**Issues or Versions with no start date or due date will not be rendered**

**Issues whit no estimated time, but with start date or due date will be rendered, but the expected progress will be 0%**

## Issue due date calculation.

When a issue is created or updated, the plugin calcualte and update the issue due date, based on start date, estimated time and hours per day configuration. Hollidays are included in the calculation, if they are presents. Also bulk updates and create relantionship triggers due date calculation.

The Plugin does not need any extra configurations, it uses default values. Hour per day default is: 8hs per day and none hollidays.

There are 2 principal values you can set up, hour per day and hollidays.

Example, if start date is 18/05 and estimated time is 16hs, then due date will be 19/05, since issue duration is 2 days (16 / 8). Then if you add a holliday on 19/05, due date will be 22/05, since duration does not change, but 19 is a holliday, and 20 and 21 are weekends, so issue will be finish on 22.

Also you can create a custom field, named “asignacion” at issue level, user level or project level. The plugin will take the value in that order, and uses this value instead of hours per day configuration.

In the previuos example, if custom field "asignacion" at issue level is 16hs, then due date will be 18/05, since one day is enough to complete the work.

If issue start date is on holliday or on weekend then plugin will find the next working day.

If you do not want the plugin calculate the start date and due date you can unckeck the option "Calculate issue end date" in the configuration page.

## Installation notes

**Attention** This plugin extends core functions

* Download zip and go to Redmine plugins folder and unzip the plugin 
* Or go to Redmine plugins folder and run “git clone https://github.com/luciof55/plus_gantt.git”
* Execute "cd .."
* Execute "bundle exec rake redmine:plugins RAILS_ENV=production"
* Then enable the plugin “Administration->Plugins” for projects
* Also you must set roles permissions, go to Administration -> Roles -> Permissions report, look for Plusgantt and check the roles you want.

## Develop Environment
* Redmine version                3.3.3.stable
* Ruby version                   2.3.0-p0 (2015-12-25) [x64-mingw32]
* Rails version                  4.2.6
* Environment                    production
* Database adapter               Mysql2
