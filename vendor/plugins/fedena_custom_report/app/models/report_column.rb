class ReportColumn < ActiveRecord::Base
  belongs_to :report
  before_save :set_default_title
  default_scope  :order=>"position"
  def set_default_title
    self.title = self.method.titleize if self.title.blank?
  end  
end
