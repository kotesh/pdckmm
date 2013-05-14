require 'translator'
require 'fastercsv'

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

config.after_initialize do
  Course.class_eval{def to_s;"#{course_name}";end}
end
FedenaPlugin.register = {
  :name=>"fedena_custom_report",
  :description=>"Fedena Custom Report Module",
  :auth_file=>"config/custom_reports_auth.rb",
  :more_menu=>{:title=>"custom_report",:controller=>"custom_reports",:action=>"index",:target_id=>"more-parent"},
  :css_overrides=>[{:controller=>"user",:action=>"dashboard"}],
  :autosuggest_menuitems=>[
    {:menu_type => 'link' ,:label => "autosuggest_menu.custom_reports",:value =>{:controller => :custom_reports,:action => :index}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.new_student_report",:value =>{:controller => :custom_reports,:action => :new, :id=>'student'}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.new_employee_report",:value =>{:controller => :custom_reports,:action => :new, :id=>'employee'}}
  ],
  :multischool_models=>%w{Report ReportColumn ReportQuery}
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

ActionView::live_validations = false
