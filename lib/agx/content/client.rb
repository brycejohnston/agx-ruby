module Agx
  module Content
    class Client
      attr_accessor :client_id, :client_secret, :site, :token_url, :version

      def initialize(client_id: nil, client_secret: nil, version: nil, prod: true)
        domain = (prod ? "agxplatform.com" : "qaagxplatform.com")
        @client_id = client_id || ENV['AGX_CONTENT_CLIENT_ID']
        @client_secret = client_secret || ENV['AGX_CONTENT_CLIENT_SECRET']
        @site = "https://refdata.#{domain}"
        @token_url = "https://auth.#{domain}/identity/connect/token"
        @version = version || "v1"
        @client = set_client
        @token = {
          access_token: nil,
          expires_at: nil
        }
      end

      def get(resource, params = {})
        validate_credentials

        resource = "/api/#{@version}/#{resource}"
        begin
          response = current_token.get(resource, {:headers => { "oauth-scopes" => "referencedata" }, :params => params})
          parse_response(response.body)
        rescue => e
          handle_error(e)
        end
      end

      protected

      def validate_credentials
        unless @client_id && @client_secret
          error = Agx::Error.new("agX Client Credentials Not Set", {title: "AGX_CREDENTIALS_ERROR"})
          raise error
        end
      end

      def parse_response(response_body)
        parsed_response = nil

        if response_body && !response_body.empty?
          begin
            parsed_response = Oj.load(response_body)
          rescue Oj::ParseError
            error = Agx::Error.new("Unparseable response: #{response_body}")
            error.title = "UNPARSEABLE_RESPONSE"
            error.status_code = 500
            raise error
          end
        end

        parsed_response
      end

      def handle_error(error)
        error_params = {}

        begin
          if error.is_a?(OAuth2::Error) && error.response
            error_params[:title] = "HTTP_#{error.response.status}_ERROR"
            error_params[:status_code] = error.response.status
            error_params[:raw_body] = error.response.body
            error_params[:body] = Oj.load(error.response.body)
          elsif error.is_a?(Errno::ETIMEDOUT)
            error_params[:title] = "TIMEOUT_ERROR"
          end
        rescue Oj::ParseError
        end

        error_to_raise = Agx::Error.new(error.message, error_params)
        raise error_to_raise
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

        new_token
      end

      def api_token
        begin
          new_token = @client.client_credentials.get_token(
            {
              'client_id' => @client_id,
              'client_secret' => @client_secret,
              'scope' => "referencedata"
            }
          )
        rescue => e
          handle_error(e)
        end

        @token[:access_token] = new_token.token
        @token[:expires_at] = new_token.expires_at

        OAuth2::AccessToken.new @client, new_token.token
      end

      def set_client
        @client = OAuth2::Client.new(
          @client_id,
          @client_secret,
          site: @site,
          token_url: @token_url,
          connection_opts: {
            request: { timeout: 90 }
          }
        )
      end

    end
  end
end
