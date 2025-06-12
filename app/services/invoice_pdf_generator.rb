class InvoicePdfGenerator
    include Prawn::View

    def initialize(invoice)
      @invoice = invoice
      @student = @invoice.semester_registration.student
      @document = Prawn::Document.new(page_size: 'A4', margin: 40)
    end

    def render
      header
      student_info
      invoice_info
      course_table
      totals
      payment_info
      footer
      @document.render
    end

    private

    def header
      @document.image 'app/assets/images/logo3.jpg', width: 100, position: :center
      @document.move_down 20
      @document.text 'Premier College', size: 28, style: :bold, align: :center
      @document.move_down 10
      @document.text 'Invoice', size: 16, style: :bold, align: :center
      @document.text 'Kality Menaharia around Total behind Quara Hotel, Addis Ababa, Ethiopia', size: 12, align: :center
      @document.text 'Phone: +251908522222', size: 12, align: :center
      @document.text 'Email: info@premiercollege.edu.et', size: 12, align: :center
      @document.move_down 30
    end

    def student_info
      @document.fill_color '003366'
      @document.text 'Bill To:', size: 15, style: :bold
      @document.fill_color '000000'
      @document.text "#{@student.name.full}", size: 12
      @document.text "ID: #{@student.student_id}", size: 12
      @document.text "Email: #{@student.email}", size: 12
      @document.move_down 20
    end

    def invoice_info
      @document.fill_color '003366'
      @document.text 'Invoice Details:', size: 15, style: :bold
      @document.fill_color '000000'
      @document.text "Invoice Number: #{@invoice.invoice_number}", size: 12
      @document.text "Invoice Date: #{@invoice.created_at.strftime('%b %d, %Y')}", size: 12
      @document.text "Payment Due: #{@invoice.due_date.strftime('%b %d, %Y')}", size: 12 if @invoice.due_date.present?
      @document.move_down 20
    end

    def course_table
      @document.fill_color '003366'
      @document.text 'Course Details:', size: 15, style: :bold
      @document.fill_color '000000'
      table_data = [['Course Title', 'Module Code', 'Course Code', 'Credit Hour']]

      courses = @student.get_current_courses

      courses.each do |course|
        table_data << [
          course.course_title,
          course.course_module.module_code,
          course.course_code,
          course.credit_hour
        ]
      end

      @document.table(table_data, header: true, row_colors: %w[E0E0E0 FFFFFF],
                                  cell_style: { border_width: 0.5, padding: [8, 12], size: 10 }, position: :center)
      @document.move_down 20
    end

    def totals
      @document.fill_color '003366'
      @document.text 'Total Amount:', size: 15, style: :bold
      @document.fill_color '000000'
      @document.text "Subtotal: #{@invoice.total_price.round(2)} ETB", size: 12
      @document.text "Registration Fee: #{@invoice.registration_fee} ETB", size: 12
      @document.text "Total: #{(@invoice.total_price + @invoice.registration_fee).round(2)} ETB", size: 12, style: :bold
      @document.move_down 20
    end

    def payment_info
      # return unless @invoice.payment_transaction.present?
  #
      # @document.fill_color "003366"
      # @document.text "Payment Transfer Details", size: 15, style: :bold
      # @document.fill_color "000000"
      # @document.text "Account Holder: #{@invoice.payment_transaction.account_holder_fullname}", size: 12
      # @document.text "Account Number: #{@invoice.payment_transaction.account_number}", size: 12
      # @document.text "Phone: #{@invoice.payment_transaction.phone_number}", size: 12
      # @document.text "Payment Method: #{@invoice.payment_transaction.payment_method.bank_name}", size: 12
      # @document.move_down 20
    end

    def footer
      # @document.move_down 30
      # @document.text "Thank you for your business!", size: 12, style: :italic, align: :center
    end
end
