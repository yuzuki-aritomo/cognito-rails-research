require 'aws-sdk-cognitoidentityprovider'

class CognitoService
  def initialize
    @user_pool_id = ENV['COGNITO_USER_POOL_ID']
    @client_id = ENV['COGNITO_CLIENT_ID']
    @client_secret = ENV['COGNITO_CLIENT_SECRET']
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

    {
      access_token: response.authentication_result.access_token,
      refresh_token: response.authentication_result.refresh_token
    }
  end

  def refresh_token(refresh_token)
    response = @client.initiate_auth(
      client_id: @client_id,
      auth_flow: 'REFRESH_TOKEN_AUTH',
      auth_parameters: {
        'REFRESH_TOKEN' => refresh_token
      }
    )
    {
      access_token: response.authentication_result.access_token,
      refresh_token: response.authentication_result.refresh_token
    }
  end

  def get_user(access_token)
    response = @client.get_user({ access_token: access_token })
    # subはユーザーの一意なID
    user_attributes = {}
    response.user_attributes.each do |attr|
      user_attributes[attr.name.to_sym] = attr.value
    end
    user_attributes
    # User.find_by(cognito_id: user_attributes[:sub])
  end

  def get_access_token_from_code(code)
    redirect_uri = 'http://localhost:2000/oauth2/callback'

    token_endpoint = 'https://sample-rails.auth.ap-northeast-1.amazoncognito.com/oauth2/token'

    uri = URI(token_endpoint)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form(
      code: code,
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: redirect_uri,
      grant_type: 'authorization_code'
    )

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      # エラー処理をここに記述
      response.body
    end
  end
end