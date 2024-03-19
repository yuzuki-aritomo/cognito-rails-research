class Oauth2Controller < ApplicationController
  skip_before_action :authenticate_user, only: [:callback]

  def callback
    code = params[:code]
    token = CognitoService.new.get_access_token_from_code(code)
    render json: token
  end
end
