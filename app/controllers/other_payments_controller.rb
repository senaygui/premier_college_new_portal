class OtherPaymentsController < ApplicationController
  before_action :authenticate_student!
  before_action :set_other_payment, only: %i[show edit update destroy]

  def index
    @other_payments = OtherPayment.where(student: current_student)
                                  .order(created_at: :desc)
                                  .includes(:payment_transaction, :semester_registration)
  end

  def show
    # @other_payment is set by before_action
  end

  # def new
  #   @other_payment = OtherPayment.new
  #   @other_payment.build_payment_transaction
  # end

  # def create
  #   @other_payment = OtherPayment.new(other_payment_params)
  #   @other_payment.student = current_student
  #   @other_payment.created_by = current_student.first_name
  #   @other_payment.invoice_status = 'pending'
  #   @other_payment.invoice_number = generate_invoice_number

  #   if @other_payment.save
  #     redirect_to @other_payment, notice: 'Payment request was successfully created.'
  #   else
  #     render :new, status: :unprocessable_entity
  #   end
  # end

  def edit
    # @other_payment is set by before_action
  end

  def update
    if @other_payment.update(other_payment_params)
      redirect_to @other_payment, notice: 'Payment information was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @other_payment.invoice_status == 'pending'
      @other_payment.destroy
      redirect_to other_payments_path, notice: 'Payment request was successfully cancelled.'
    else
      redirect_to @other_payment, alert: 'Cannot cancel a payment that has already been processed.'
    end
  end

  def upload_receipt
    @other_payment = OtherPayment.find(params[:id])

    if @other_payment.payment_transaction.update(receipt_params)
      @other_payment.payment_transaction.update(
        finance_approval_status: 'pending',
        last_updated_by: current_student.first_name
      )
      redirect_to @other_payment, notice: 'Receipt was successfully uploaded.'
    else
      redirect_to @other_payment, alert: 'There was an error uploading your receipt.'
    end
  end

  private

  def set_other_payment
    @other_payment = OtherPayment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to other_payments_path, alert: 'Payment request not found.'
  end

  def other_payment_params
    params.require(:other_payment).permit(
      :payable_type,
      :payable_id,
      :total_price,
      :payment_type,
      :student_full_name,
      :student_id_number,
      :section_id,
      :department_id,
      :program_id,
      :academic_calendar_id,
      :semester_registration_id,
      :due_date,
      :semester,
      :year,
      payment_transaction_attributes: %i[
        id
        payment_method_id
        account_holder_fullname
        phone_number
        account_number
        transaction_reference
        receipt_image
      ]
    )
  end

  def receipt_params
    params.require(:payment_transaction).permit(:receipt_image)
  end

  def generate_invoice_number
    loop do
      number = SecureRandom.random_number(10_000_000)
      break number unless OtherPayment.exists?(invoice_number: number)
    end
  end
end
