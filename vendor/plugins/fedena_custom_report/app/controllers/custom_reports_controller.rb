class CustomReportsController < ApplicationController
  filter_access_to :all
  before_filter :login_required
  before_filter :find_and_check_model,:only=>[:generate,:edit]
  def find_and_check_model
    @model_name = params[:id].camelize.singularize
    unless ["Student","Employee"].include? @model_name
      flash[:notice] = "#{t(@model_name.underscore)} #{t('report_cannot_be_generated')}"
      redirect_to :action=>:index
      return
    else
      @model = Kernel.const_get(@model_name)
      if @model_name == "Student"
       @search_fields = YAML::load(File.open(File.dirname(__FILE__)+'/../../config/report_fields.yml'))[:fields_to_search][:student]
       @display_fields=YAML::load(File.open(File.dirname(__FILE__)+'/../../config/report_fields.yml'))[:fields_to_display][:student]
      else
       @search_fields = YAML::load(File.open(File.dirname(__FILE__)+'/../../config/report_fields.yml'))[:fields_to_search][:employee]
       @display_fields=YAML::load(File.open(File.dirname(__FILE__)+'/../../config/report_fields.yml'))[:fields_to_display][:employee]
      end
    end
  end  
  def index
    @reports=Report.all
  end

  def generate    
    @report=Report.new
    @report.model = @model_name
    @model.extend JoinScope
    @model.extend AdditionalFieldScope
    ##@search_fields = @model.fields_to_search.deep_copy
    make_report_columns
    @search_fields.each do |type,columns|
      case type
      when :string
        columns.each do |col|
          ["like","begins_with","equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
          end
        end
      when :date
        columns.each do |col|
          ["gte","lte","equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
          end
        end
      when :association
        columns.each do |col|
          @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>"in",:column_type=>type,:field_name=>col)
        end
      when :boolean
        columns.each do |col|
          @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>"is",:column_type=>type,:field_name=>col)
        end
      when :integer
        columns.each do |col|
          ["gte","lte","equals"].each do |criteria|
            @report.report_queries.build(:table_name => @model_name,:column_name=>col,:criteria=>criteria,:column_type=>type,:field_name=>col)
          end
        end
      end

    end
    @search_fields[:additional]= @model.additional_field_methods
    @model.get_additional_fields.each do |f|
      if f.name.to_i == 0
        ["equals"].each do |criteria|
          @report.report_queries.build(:table_name => @model.additional_detail_model.to_s,:column_name=>f.id,:criteria=>criteria,:column_type=>:additional,:field_name=>f.name.downcase.gsub(" ","_"))
        end
      end
    end
    
    if request.post?
      @report = Report.new(params[:report])
      if @report.save
        flash[:notice]="#{t('report_created_successfully')}"
        redirect_to :action => "index"
      else
        render :action => "generate"
      end
    end
    
  end

  def edit
    @report=Report.find params[:id]
    @model_name=@report.model
    ##@all_columns=@model.fields_to_search
    @all_columns = @search_fields
  end

  def show
    @report=Report.find params[:id]
    @report_columns = @report.report_columns
    @report_columns.delete_if{|rc| !((@report.model_object.instance_methods+@report.model_object.column_names).include?(rc.method))}
    @column_type = Hash.new
    @report.model_object.columns_hash.each{|key,val| @column_type[key]=val.type }
    search = @report.model_object.report_search(@report.search_param)
    @search_results = search.paginate(:all,:include=>@report.include_param,:page=>params[:page])
  end

  def to_csv
    report=Report.find params[:id]
    report_columns = report.report_columns
    report_columns.delete_if{|rc| !((report.model_object.instance_methods+report.model_object.column_names).include?(rc.method))}
    csv = report.to_csv
    filename = "#{report.name}-#{Time.now.to_date.to_s}.csv"
   # hash_to_excel_csv report, filename
    send_data(csv, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

=begin  
 def to_xls
      report=Report.find params[:id]
      report_columns = report.report_columns
      report_columns.delete_if{|rc| !((report.model_object.instance_methods+report.model_object.column_names).include?(rc.method))}
      csv = report.to_csv
      filename = "#{report.name}-#{Time.now.to_date.to_s}.csv"
      send_data(xls, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end
=end 
  
  def delete
    if Report.destroy params[:id]
      flash[:notice]="#{t('report_deleted_successfully')}."
    else
      flash[:notice]="#{t('report_delete_error')}."
    end
    redirect_to :action=>'index'
  end
  
private
  
  def hash_to_excel_csv(collection, filename)
    keys = collection.first.keys
    resp = CSV.generate(:col_sep => ";", :force_quotes => true) do |csv|
      csv << keys.map{|i|i.to_s.titleize}
      collection.each do |job|
        csv << job.values
      end
    end

    send_data resp.encode(Encoding::ISO_8859_1, :undef => :replace),
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{filename}.csv"
  end

 private

 def make_report_columns
   ##@display_fields = ["admission_date","first_name","last_name","student_category","batch","course","admission_no","language","blood_group","date_of_birth","employee_position","employee_department","employee_grade"]
   @addition_fields = { "string" => ["admission_no","first_name","middle_name","last_name","gender","blood_group","language","religion","city","state"]}
   ##@model.fields_to_display.each do |col|
   @display_fields.each do |col|
     @report.report_columns.build(:method=>col,:title=>t(col))
   end
   @model.additional_field_methods.each do |col|
    @report.report_columns.build(:method=>col,:title=>col.to_s.titleize)
  end
 end
end
