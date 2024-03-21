class SessionsController < ApplicationController
  skip_before_action :authenticate_user

  def signup
    cognito_service = CognitoService.new
    user = cognito_service.create_user(params[:username], params[:phone_number], params[:password])
    User.create!(cognito_sub: user[:user_sub], username: params[:username], phone_number: params[:phone_number])

    res = params[:user_type].map do |type|
      cognito_service.add_user_to_group(params[:username], type)
    end

    render json: { user: user, group: res }
  end

  def confirm_user
    cognito_service = CognitoService.new
    user = cognito_service.confirm_user(params[:username], params[:confirmation_code])
    render json: { user: user }
  end

  def login
    render json: { message: 'login' }
  end
end
