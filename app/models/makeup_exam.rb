class MakeupExam < ApplicationRecord
   # Callbacks
   after_create :generate_invoice_for_makeup_exam
   after_save :makeup_exam_update_status

   # Validations
   validates :year, presence: true
   validates :semester, presence: true
   validates :reason, presence: true

   # Associations
   belongs_to :course
   belongs_to :program, optional: true
   belongs_to :department, optional: true
   belongs_to :section, optional: true
   belongs_to :academic_calendar
   belongs_to :student
   belongs_to :course_registration, optional: true
   belongs_to :student_grade, optional: true
   belongs_to :assessment, optional: true
   has_one :other_payment, as: :payable, dependent: :destroy
   has_one_attached :attachment

   # Custom Validations
   validate :limit_assessment_result
   validate :acceptable_attachment

   has_one_attached :receipt
   def acceptable_attachment
     return unless attachment.attached?

     errors.add(:attachment, 'is too big') unless attachment.byte_size <= 10.megabytes

     acceptable_types = ['image/jpeg', 'image/png', 'application/pdf']
     errors.add(:attachment, 'must be a JPEG, PNG, or PDF') unless acceptable_types.include?(attachment.content_type)
   end

     private

   def limit_assessment_result
     if add_mark && assessment && add_mark > assessment.result
       errors[:add_mark] << 'The assessment result reached the maximum value'
     end
   end

   def generate_invoice_for_makeup_exam
       OtherPayment.create do |invoice|
         invoice.student_id = student.id
         invoice.academic_calendar_id = academic_calendar_id
         invoice.semester_registration_id = course_registration.semester_registration_id
         invoice.department_id = department_id
         invoice.program_id = program_id
         invoice.section_id = section_id
         invoice.payable_type = 'MakeupExam'
         invoice.payment_type = 'Makeup Exam'
         invoice.payable_id = id
         invoice.year = year
         invoice.semester = semester
         invoice.student_id_number = student.student_id
         invoice.student_full_name = course_registration.student_full_name
         invoice.created_by = 'system'
         invoice.due_date = Time.now + 10.days
         invoice.invoice_status = 'unpaid'
         invoice.invoice_number = SecureRandom.random_number(10_000_000)
         invoice.total_price = CollegePayment.where(study_level: student.study_level,
                                                    admission_type: student.admission_type).first.makeup_exam_fee
       end
   end

   # def verified_status
   #	if department_approval == "approved" && dean_approval == "approved" && instructor_approval == "approved" && registrar_approval == "approved" && academic_affair_approval == "approved"
   #	  Rails.logger.info "All conditions met, updating status to true"
   #	  self.update_columns(status: "true", verified: true)
   #	else
   #	  Rails.logger.info "Conditions not met: department_approval: #{department_approval}, dean_approval: #{dean_approval}, instructor_approval: #{instructor_approval}, registrar_approval: #{registrar_approval}, academic_affair_approval: #{academic_affair_approval}"
   #	end
   # end

   def makeup_exam_update_status
     if other_payment.payment_transaction.present? && (other_payment.payment_transaction.last.finance_approval_status == 'approved' && add_mark.present?)
          assessment.where(student_grade_id: student_grade.id).where(final_exam: true).update(result: add_mark)
          student_grade.skip_assessment_total_calc = true
          student_grade.update(assesment_total: student_grade.assessments.sum(:result)) if student_grade.present?
          update_columns(current_result_total: student_grade.assesment_total) if student_grade.present?
          update_columns(current_letter_grade: student_grade.letter_grade) if student_grade.present?
          update_columns(status: 'approved')
     end
   end

   #  def makeup_exam_update_status
   #    if payment_approved? && add_mark.present?
   #      assessment.update(result: add_mark) if assessment.present?
   #      student_grade.update(assesment_total: student_grade.assessments.sum(:result)) if student_grade.present?
   #      update_columns(current_result_total: student_grade.assesment_total) if student_grade.present?
   #      update_columns(current_letter_grade: student_grade.letter_grade) if student_grade.present?
   #      update_columns(status: 'approved')
   #    end
   #  end

   def approved_by_all?
     department_approval == 'approved' && registrar_approval == 'approved' &&
       dean_approval == 'approved' && instructor_approval == 'approved' &&
       academic_affair_approval == 'approved'
   end

   def payment_approved?
     other_payment.present? && other_payment.payment_transaction.present? &&
       other_payment.payment_transaction.finance_approval_status == 'approved' &&
       other_payment.invoice_status == 'approved'
   end
end

# class MakeupExam < ApplicationRecord
#	# after_save :current_grade
#	after_save :generate_invoice_for_makeup_exam
#	after_save :makeup_exam_update_status
#	##validations
#		validates :year, :presence => true
#		validates :semester, :presence => true
#		validates :previous_result_total, :presence => true
#		validates :previous_letter_grade, :presence => true
#		validates :reason, :presence => true
#		# validate :limit_assessment_result
#
#	##associations
#	  belongs_to :course
#	  belongs_to :program, optional: true
#	  belongs_to :department, optional: true
#	  belongs_to :section, optional: true
#	  belongs_to :academic_calendar
#	  belongs_to :student
#	  belongs_to :course_registration, optional: true
#		belongs_to :student_grade, optional: true
#		belongs_to :assessment
#		has_one :other_payment, as: :payable, dependent: :destroy
#
#	private
#		def limit_assessment_result
#	    if self.add_mark > self.assessment.result
#	      self.errors[:add_mark] << "The assessment result reached the maximum value"
#	    end
#	  end
#
#		def generate_invoice_for_makeup_exam
#			if (self.department_approval == "approved") && (self.registrar_approval == "approved") && (self.dean_approval == "approved") && (self.instructor_approval== "approved") && (self.academic_affair_approval== "approved") && (!self.other_payment.present?)
#				OtherPayment.create do |invoice|
#					invoice.student_id = self.student.id
#					invoice.academic_calendar_id = self.academic_calendar_id
#					invoice.semester_registration_id = self.course_registration.semester_registration_id
#					invoice.department_id = self.department_id
#					invoice.program_id = self.program_id
#					invoice.section_id = self.section_id
#					invoice.payable_type = "MakeupExam"
#					invoice.payment_type = "Makeup Exam"
#					invoice.payable_id = self.id
#					invoice.year = self.year
#					invoice.semester = self.semester
#					invoice.student_id_number = self.student.student_id
#					invoice.student_full_name = self.course_registration.student_full_name
#					invoice.created_by = "system"
#					invoice.due_date = Time.now + 10.day
#					invoice.invoice_status = "unpaid"
#					invoice.invoice_number = SecureRandom.random_number(10000000)
#					invoice.total_price =  CollegePayment.where(study_level: self.student.study_level,admission_type: self.student.admission_type).first.makeup_exam_fee
#				end
#			end
#		end
#		def makeup_exam_update_status
#			if (self.other_payment.present?) &&(self.other_payment.payment_transaction.present?) && (self.other_payment.payment_transaction.finance_approval_status == "approved") && (self.other_payment.invoice_status == "approved") && (self.add_mark.present?)
#				self.assessment.update(result: self.add_mark)
#			  self.student_grade.update(assesment_total: self.student_grade.assessments.sum(:result))
#			  self.update_columns(current_result_total: self.student_grade.assesment_total)
#			  self.update_columns(current_letter_grade: self.student_grade.letter_grade)
#				self.update_columns(status: "approved")
#	    end
#		end
# end
#
