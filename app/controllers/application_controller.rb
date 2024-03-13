class ApplicationController < ActionController::API
  before_action :authenticate_user

  def authenticate_user
    token = request.headers['access-token']
    return render json: { error: 'access-token is required' }, status: :unauthorized if token.nil?

    user = CognitoService.new.get_user(token)
    @current_user = user
    # @current_user = User.find_by(cognito_id: user[:sub])
  rescue => e
    render json: { error: e.message }, status: :unauthorized
  end
end
