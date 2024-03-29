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
    cognito_service = CognitoService.new
    token = cognito_service.login(params[:id], params[:password])
    cookies['access-token'] = {
      value: token[:access_token],
      httponly: true,
      secure: Rails.env.production?,
      expires: 1.hour.from_now,
    }
    cookies['refresh-token'] = {
      value: token[:refresh_token],
      httponly: true,
      secure: Rails.env.production?,
      expires: 1.month.from_now,
    }
    render json: { token: token }
  end

  def forgot_password
    cognito_service = CognitoService.new
    cognito_service.forgot_password(params[:username])
    render json: { message: 'success' }
  end

  def confirm_forgot_password
    cognito_service = CognitoService.new
    cognito_service.confirm_forgot_password(params[:username], params[:confirmation_code], params[:password])
    render json: { message: 'success' }
  end
end
