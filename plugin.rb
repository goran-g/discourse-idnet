# name: idnet
# about: Idnet login
# version: 0.1
# authors: Yvon Cognard

require_dependency 'auth/oauth2_authenticator.rb'

PLUGIN_NAME = 'idnet'
IDNET_HOST = 'https://www.id.net'

AUTHORIZE_URL = File.join(IDNET_HOST, 'oauth/authorize')
TOKEN_URL = File.join(IDNET_HOST, 'oauth/token')
PROFILE_URL = File.join(IDNET_HOST, 'api/v1/json/profile')

class IdnetAuthenticator < ::Auth::OAuth2Authenticator
  class User
    def initialize(token)
      @token = token
      fetch
    end

    def self.fetch(token)
      new(token)
    end

    def auth_result
      return @auth_result if @auth_result

      @auth_result = Auth::Result.new
      @auth_result.name = @name
      @auth_result.username = @username
      @auth_result.email = @email
      @auth_result.email_valid = @email.present?
      @auth_result.extra_data = { :"#{PLUGIN_NAME}_user_id" => @user_id }
      @auth_result.user = find_or_create_record
      @auth_result
    end

    private

    def fetch
      body = open(PROFILE_URL, 'Authorization' => "Bearer #{@token}").read
      json = JSON.parse(body)

      return if json.blank?

      @user_id = json['pid']
      @username = json['nickname']
      @name = json['first_name']
      @email = json['email']
    end

    def find_or_create_record
      ::User.find_or_create_by(email: @email) do |user|
        user.username = @username
        user.active = true
      end
    end
  end

  def initialize
    super(PLUGIN_NAME)
  end

  def register_middleware(omniauth)
    omniauth.provider(
      :oauth2,
      name: PLUGIN_NAME,
      setup: method(:setup_strategy)
    )
  end

  def after_authenticate(auth)
    User.fetch(auth['credentials']['token']).auth_result
  end

  private

  def setup_strategy(env)
    o = env['omniauth.strategy'].options

    o[:client_id] = client_id
    o[:client_secret] = client_secret
    o[:provider_ignores_state] = true
    o[:client_options] = { authorize_url: AUTHORIZE_URL, token_url: TOKEN_URL }
    o[:token_params] = { headers: { 'Authorization' => basic_auth_header } }
  end

  def basic_auth_header
    "Basic " + Base64.strict_encode64("#{client_id}:#{client_secret}")
  end

  def client_id
    setting(:client_id)
  end

  def client_secret
    setting(:client_secret)
  end

  def setting(key)
    SiteSetting.send("#{PLUGIN_NAME}_#{key}")
  end
end

enabled_site_setting :"#{PLUGIN_NAME}_enabled"

auth_provider(
  title_setting: "#{PLUGIN_NAME}_button_title",
  enabled_setting: enabled_site_setting,
  authenticator: IdnetAuthenticator.new,
  message: PLUGIN_NAME.capitalize,
  frame_width: 920,
  frame_height: 800
)

register_css <<CSS
  button.btn-social.#{PLUGIN_NAME} {
    background-color: #6d6d6d;
  }
CSS

register_asset 'javascripts/idnet_auto_login.js'
