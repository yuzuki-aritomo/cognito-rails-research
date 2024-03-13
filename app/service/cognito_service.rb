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

  def login(email, password)
    response = @client.initiate_auth(
      client_id: @client_id,
      auth_flow: 'USER_PASSWORD_AUTH',
      auth_parameters: {
        'USERNAME' => email,
        'PASSWORD' => password
      }
    )

    response.authentication_result.access_token
  end

  def get_user(access_token)
    response = @client.get_user({ access_token: access_token })
    response.user_attributes
  end

  private

  def get_user_from_token(token)
    # アクセストークンからユーザー情報を取得する処理
    payload = token.split('.')[1]
    decoded_payload = Base64.decode64(payload.tr('-_', '+/'))
    JSON.parse(decoded_payload)
  end
end