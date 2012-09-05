# lifted from from the example at
# http://code.google.com/p/google-api-ruby-client/source/browse/oauth/oauth_util.rb?repo=samples

require 'thin'
require 'launchy'
require 'google/api_client'
require 'google/api_client/client_secrets'

# Small helper for the sample apps for performing OAuth 2.0 flows from the command
# line. Starts an embedded server to handle redirects.
class CommandLineOAuthHelper
  USER_DATA_FILE = File.expand_path('~') + '/.paythesitter_auth'
  def initialize(scope)
    credentials = Google::APIClient::ClientSecrets.load
    client_secrets_data = {  :authorization_uri => credentials.authorization_uri,
      :token_credential_uri => credentials.token_credential_uri,
      :client_id => credentials.client_id,
      :client_secret => credentials.client_secret,
      :redirect_uri => credentials.redirect_uris.first,
      :scope => scope }
    if File.exist? (USER_DATA_FILE)
      user_data = { :access_token =>  File.open(USER_DATA_FILE, 'r') { |file| file.read }}
    end
    @authorization = Signet::OAuth2::Client.new(client_secrets_data.merge(user_data || {}))
  end
  
  # Request authorization. Opens a browser and waits for response
  def authorize
    auth = @authorization
    if @authorization.access_token
      return @authorization
    end
    url = @authorization.authorization_uri().to_s
    server = Thin::Server.new('0.0.0.0', 3000) do
      run lambda { |env|
          # Exchange the auth code & quit 
          req = Rack::Request.new(env)
          auth.code = req['code']
          auth.fetch_access_token!
          server.stop() 
          [200, {'Content-Type' => 'text/plain'}, 'OK'] 
      }
    end

    Launchy.open(url)
    server.start()
    File.write(USER_DATA_FILE, @authorization.access_token)
    return @authorization
  end
end
