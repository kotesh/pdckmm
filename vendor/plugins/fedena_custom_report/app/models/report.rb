class Report < ActiveRecord::Base
  
  has_many :report_queries,:dependent => :destroy
  has_many :report_columns,:dependent => :destroy

  accepts_nested_attributes_for  :report_columns
  accepts_nested_attributes_for :report_queries,
    :reject_if => proc { |attributes|
    attributes['query'].blank? and (attributes['date_query(1i)'].blank? or
        attributes['date_query(2i)'].blank? or
        attributes['date_query(3i)'].blank?)
  }

  validates_presence_of :name, :report_columns, :report_queries

  def after_initialize
    unless model_object.nil?
      model_object.extend JoinScope
      model_object.extend AdditionalFieldScope
    end
  end
  
  def search_param
    sp={}
    self.report_queries.each do |rq|
      sp[rq.query_string]= rq.query unless ['join','additional'].include? rq.column_type
    end
    sp[:join_params]=join_params
    sp[:additional_field_params]=additional_field_params
    sp
  end
  
  def join_params
    jp={}
    cond={}
    join_queries=report_queries.group_by(&:column_type)['join']
    unless join_queries.blank?
      join_queries = join_queries.group_by(&:table_name)
      jp[:joins] = join_queries.keys.collect{|k| eval(k).table_name.singularize.to_sym}
      join_queries.each do |k,rqs|
        cond[k]=[]
        rqs.each do |rq|
          cond[k] << rq.make_query
        end
      end
      q_str=[]
      cond.values.each do |str|
        q_str << "(#{str.join(" OR ")})"
      end
      jp[:conditions]=[q_str.join(" AND ")]
    end
    jp
  end
  
  def additional_field_params
    ap={}
    cond={}
    additional_field_queries = report_queries.group_by(&:column_type)['additional']
    unless additional_field_queries.blank?
      additional_field_queries = additional_field_queries.group_by(&:table_name)
      ap[:joins] = additional_field_queries.keys.collect{|k| eval(k).table_name.to_sym}
      additional_field_queries.each do |k,rqs|
        cond[k]=[]
        rqs.each do |rq|
          cond[k] << rq.make_query_for_additional_field
        end
      end
      q_str=[]
      cond.values.each do |str|
        q_str << "(#{str.join(" OR ")})"
      end
      ap[:conditions]=[q_str.join(" OR ")]
    end
    ap
  end

  def include_param
    ip=[]
    model_name = Kernel.const_get(self.model)    
    self.report_columns.each do |rc|
      ##(ip << rc.method.to_sym ) if model_name.fields_to_search[:association].include? rc.method.to_sym
    end
    ip
  end
  def to_csv
    csv = FasterCSV.generate do |csv|
      cols = self.report_columns.collect{|rc| rc.title}
      csv << cols
      search_results = model_object.report_search(self.search_param).all(:include=>self.include_param)
      search_results.each do |obj|
        cols = []
        self.report_columns.each do |col|
          cols << "#{obj.send(col.method)}"
        end
        csv << cols
      end
    end
    csv
  end

  def model_object
    Kernel.const_get(self.model) unless self.model.nil?
  end
end
  
