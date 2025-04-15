class Withdrawal < ApplicationRecord

	##validation
		validates :semester, :presence => true
		validates :year, :presence => true
		validates :fee_status, :presence => true
		validates :reason_for_withdrawal, :presence => true
		validates :last_class_attended, :presence => true
  ##assocations
	  belongs_to :program
	  belongs_to :department
	  belongs_to :student
	  belongs_to :section
	  belongs_to :academic_calendar

	  ## Callback to check approvals after any update
  after_update :check_approvals

  ## Check if all approvals are approved
  def all_approvals_approved?
	puts "Finance Head Approval: #{finance_head_approval}"
	puts "Registrar Approval: #{registrar_approval}"
	puts "Dean Approval: #{dean_approval}"
	puts "Department Approval: #{department_approval}"
	puts "Library Head Approval: #{library_head_approval}"
  
	finance_head_approval == 'approved' &&
	registrar_approval == 'approved' &&
	dean_approval == 'approved' &&
	department_approval == 'approved' &&
	library_head_approval == 'approved'
  end
  
  def check_approvals
	if all_approvals_approved?
	  puts "All approvals are approved. Updating student account status."
		if reason_for_withdrawal == 'Graduating Student'
			student.update(account_status: 'inactive')
			student.update(graduation_status: 'approved')
		else
			student.update(account_status: 'inactive')
		end
	else
	  puts "Not all approvals are approved."
	end
  end

  after_save :check_approvals
end
