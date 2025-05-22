class EmailsController < ApplicationController
  def check
    email = params[:email].to_s.strip.downcase
    taken = Student.exists?(email:)
    render json: { taken: }
  end
end
