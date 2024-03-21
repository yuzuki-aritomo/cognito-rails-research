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

  def generate_secret_hash(username)
    message = username + @client_id
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), @client_secret, message)
    Base64.strict_encode64(hmac)
  end

  def create_user(username, phone_number, password, email=nil)
    @client.sign_up(
      client_id: @client_id,
      username: username,
      password: password,
      user_attributes: [
        # {name: 'email', value: email},
        {name: 'phone_number', value: phone_number},
      ],
      validation_data: [{name: 'phone_number', value: phone_number}],
      secret_hash: generate_secret_hash(username)
    )
  end

  def confirm_user(username, confirmation_code)
    @client.confirm_sign_up(
      client_id: @client_id,
      username: username,
      confirmation_code: confirmation_code,
      secret_hash: generate_secret_hash(username)
    )
  end

  def login(username, password)
    response = @client.initiate_auth(
      client_id: @client_id,
      auth_flow: 'USER_PASSWORD_AUTH',
      auth_parameters: {
        'USERNAME' => username,
        'PASSWORD' => password,
        'SECRET_HASH' => generate_secret_hash(username),
      }
    )

    {
      access_token: response.authentication_result.access_token,
      refresh_token: response.authentication_result.refresh_token,
      device_key: response.authentication_result.new_device_metadata.device_key,
    }
  end

  def device_auth(username, device_key, srp_a)
    srp_a = @client.generate_srp_a({ user_id: username, client_id: @client_id, secret_hash: generate_secret_hash(username) })
    response = @client.initiate_auth(
      client_id: @client_id,
      auth_flow: 'DEVICE_SRP_AUTH',
      auth_parameters: {
        'USERNAME' => username,
        'DEVICE_KEY' => device_key,
        'SRP_A' => srp_a
      }
    )
    response
  end

  def confirm_device(access_token, device_key)
    response = @client.confirm_device(
      access_token: access_token,
      device_key: device_key,
      device_name: 'dummy',
      # secret_hash: generate_secret_hash(username),
      # username: username,
    )
    response
  end

  def update_device_status(access_token, device_key)
    response = @client.update_device_status(
      access_token: access_token,
      device_key: device_key,
      device_remembered_status: 'remembered',
    )
    response
  end

  def respond_to_auth_challenge(username, device_key = 'dummy')
    response = @client.respond_to_auth_challenge(
      client_id: @client_id,
      challenge_name: 'DEVICE_SRP_AUTH',
      challenge_responses: {
        'USERNAME' => username,
        'DEVICE_KEY' => device_key,
        'SECRET_HASH' => generate_secret_hash(username)
      }
    )

    {
      access_token: response.authentication_result.access_token,
      refresh_token: response.authentication_result.refresh_token
    }
  end

  def list_devices(access_token)
    response = @client.list_devices(
      access_token: access_token,
      limit: 10  # 取得するデバイスの最大数を指定（オプション）
    )

    devices = response.devices

    puts "User devices: #{devices}"
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

  def describe_user_pool
    response = @client.describe_user_pool({ user_pool_id: @user_pool_id })
    puts response.user_pool.device_configuration
    if response.user_pool.device_configuration
      puts "デバイス追跡が有効: #{response.user_pool.device_configuration.device_only_remembered_on_user_prompt?}"
      puts "新しいデバイスに対してチャレンジが必要: #{response.user_pool.device_configuration.challenge_required_on_new_device?}"
    end
  end

  def update_user_pool
    @client.update_user_pool(
      user_pool_id: @user_pool_id,
      device_configuration: {
        device_only_remembered_on_user_prompt: true,
        challenge_required_on_new_device: false
      }
    )
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
    token_endpoint = 'https://sample-signup.auth.ap-northeast-1.amazoncognito.com/oauth2/token'

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

  def add_user_to_group(username, group_name)
    @client.admin_add_user_to_group(
      user_pool_id: @user_pool_id,
      username: username,
      group_name: group_name,
    )
  end

  def remove_user_from_group(username, group_name)
    @client.admin_remove_user_from_group(
      user_pool_id: @user_pool_id,
      username: username,
      group_name: group_name,
    )
  end

  def forgot_password(username)
    @client.forgot_password(
      client_id: @client_id,
      username: username,
      secret_hash: generate_secret_hash(username)
    )
  end

  def confirm_forgot_password(username, confirmation_code, password)
    @client.confirm_forgot_password(
      client_id: @client_id,
      username: username,
      confirmation_code: confirmation_code,
      password: password,
      secret_hash: generate_secret_hash(username)
    )
  end

end