class SessionsController < ApplicationController
  skip_before_action :authenticate_user

  def signup
    cognito_service = CognitoService.new
    user = cognito_service.create_user(params[:username], params[:phone_number], params[:password])

    render json: { user: user }
  end

  def confirm_user
    cognito_service = CognitoService.new
    user = cognito_service.confirm_user(params[:phone_number], params[:confirmation_code])
    render json: { user: user }
  end

  def login
    render json: { message: 'login' }
  end
end
