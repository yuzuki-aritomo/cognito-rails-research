require 'aws-sdk-cognitoidentityprovider'

class CognitoService
  def initialize
    @user_pool_id = ENV['COGNITO_USER_POOL_ID']
    @client_id = ENV['COGNITO_CLIENT_ID']
    @client = Aws::CognitoIdentityProvider::Client.new(
      region: 'ap-northeast-1',
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )
  end

  def create_user(email, password)
    @client.sign_up(
      client_id: @client_id,
      username: email,
      password: password,
      user_attributes: [
        {name: 'email', value: email}
      ]
    )
  end

  def confirm_user(email, confirmation_code)
    @client.confirm_sign_up(
      client_id: @client_id,
      username: email,
      confirmation_code: confirmation_code
    )
  end
end