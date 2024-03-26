class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :authenticate_user

  def authenticate_user
    token = cookies['access-token']
    return render json: { error: 'access-token is required' }, status: :unauthorized if token.nil?

    user = CognitoService.new.get_user(token)
    @current_user = User.find_by(cognito_sub: user[:sub])
    @groups = CognitoService.new.get_user_groups(@current_user[:username])
  rescue => e
    logger.error e.message
    render json: { error: e.message }, status: :unauthorized
  end
end
