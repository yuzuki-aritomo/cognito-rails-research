class ApplicationController < ActionController::API
  before_action :authenticate_user

  def authenticate_user
    token = request.headers['access-token']
    return render json: { error: 'access-token is required' }, status: :unauthorized if token.nil?

    user = CognitoService.new.get_user(token)
    logger.debug("user: #{user}")

    @current_user = User.find_by(cognito_sub: user[:sub])
    logger.debug("current_user: #{@current_user}")
    @groups = CognitoService.new.get_user_groups(@current_user[:username])
  rescue => e
    render json: { error: e.message }, status: :unauthorized
  end
end
