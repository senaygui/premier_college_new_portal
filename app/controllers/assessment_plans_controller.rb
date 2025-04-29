class AssessmentPlansController < ApplicationController
    # before_action :set_course
  
    # def create
    #   @assessment_plan = @course.assessment_plans.new(assessment_plan_params)
    #   if @assessment_plan.save
    #     redirect_to course_assessment_plans_path(@course), notice: 'Assessment Plan was successfully created.'
    #   else
    #     render :new
    #   end
    # end
  
    # def update
    #   @assessment_plan = @course.assessment_plans.find(params[:id])
    #   if @assessment_plan.update(assessment_plan_params)
    #     redirect_to course_assessment_plans_path(@course), notice: 'Assessment Plan was successfully updated.'
    #   else
    #     render :edit
    #   end
    # end
  
    # private
  
    # def set_course
    #   @course = Course.find(params[:course_id])
    # end
  
    # def assessment_plan_params
    #   params.require(:assessment_plan).permit(:assessment_title, :assessment_weight, :final_exam, :created_by, :updated_by, :admin_user_id)
    # end
  end
  