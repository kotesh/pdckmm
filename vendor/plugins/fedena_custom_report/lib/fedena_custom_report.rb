#FedenaCustomReports
require File.join(RAILS_ROOT, "app","models","student.rb")
require "report_extensions"
Student.extend StudentExtensions
Employee.extend EmployeeExtensions
Batch.class_eval{def to_s;"#{full_name}";end}
StudentCategory.class_eval{def to_s;"#{name}";end}
EmployeeDepartment.class_eval{def to_s;"#{name}";end}
EmployeeGrade.class_eval{def to_s;"#{name}";end}
EmployeePosition.class_eval{def to_s;"#{name}";end}
Country.class_eval{def to_s;"#{name}";end}
Guardian.class_eval{def to_s;"#{first_name}";end}

# if there is special scope for associated field make an alias to the scope method :report_data
Batch.instance_eval do
  alias :report_data :active
end

class FedenaCustomReport
end