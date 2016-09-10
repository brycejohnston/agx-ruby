module Agx
  module Content
    class Client
      attr_accessor :client_id, :client_secret, :site, :token_url, :version

      def initialize(client_id: nil, client_secret: nil, site: nil, token_url: nil, version: nil)
        @client_id = client_id || ENV['AGX_CONTENT_CLIENT_ID']
        @client_secret = client_secret || ENV['AGX_CONTENT_CLIENT_SECRET']
        @site = site || "https://refdata.agxplatform.com"
        @token_url = token_url || "https://auth.agxplatform.com/Account/Token"
        @version = version || "v1"
        @client = set_client
        @token = {
          access_token: nil,
          expires_at: nil
        }
      end

      def retrieve(resource, params = {})
        resource = "/api/#{@version}/#{resource}"
        begin
          request = current_token.get(resource, {:headers => { "oauth-scopes" => "referencedata" }, :params => params})
        rescue OAuth2::Error, Faraday::Error, Errno::ETIMEDOUT => e
          if e&.response
            api_response = {
              'status': e.response.status,
              'message': e.message,
              'body': nil
            }
            return api_response
          else
            api_response = {
              'status': nil,
              'message': e.message,
              'body': nil
            }
            return api_response
          end
        else
          api_response = {
            'status': request.response.status,
            'message': nil,
            'body': Oj.load(request.response.body)
          }
          return api_response
        end
      end

      def current_token
        if @token[:access_token].nil? || @token[:expires_at].nil?
          new_token = api_token
        else
          oauth_token = OAuth2::AccessToken.new(
            @client,
            @token[:access_token],
            {expires_at: @token[:expires_at]}
          )
          if Time.now.to_i + 180 >= @token[:expires_at] || oauth_token.expired?
            new_token = api_token
          else
            new_token = oauth_token
          end
        end
      end

      def api_token
        begin
          new_token = @client.client_credentials.get_token(
            {
              'client_id' => @client_id,
              'client_secret' => @client_secret,
              'scope' => "referencedata"
            },
            {
              :header_format => 'Bearer'
            }
          )
        rescue OAuth2::Error, Faraday::Error, Errno::ETIMEDOUT => e
          # raise "OAuth2 Error: #{e.message}"
        else
          @token[:access_token] = new_token.token
          @token[:expires_at] = new_token.expires_at
          return OAuth2::AccessToken.new @client, new_token.token
        end
      end

      def set_client
        @client = OAuth2::Client.new(
          @client_id,
          @client_secret,
          site: @site,
          token_url: @token_url
        )
      end

    end
  end
end
