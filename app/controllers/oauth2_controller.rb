class Oauth2Controller < ApplicationController
  skip_before_action :authenticate_user, only: [:callback]

  def callback
    code = params[:code]
    token = CognitoService.new.get_access_token_from_code(code)
    user = CognitoService.new.get_user(token['access_token'])

    exist_user = User.find_by(cognito_sub: user[:sub])

    unless exist_user
      User.create(cognito_sub: user[:sub], username: user[:username])
    end

    redirect_url = "#{ENV['FRONT_URL']}/oauth2/callback?access_token=#{token['access_token']}&refresh_token=#{token['refresh_token']}"
    redirect_to redirect_url, status: 301
  end
end
