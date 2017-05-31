module Agx
  module Sync
    class Pictures
      attr_accessor :client_id, :client_secret, :site, :host, :authorize_url,
        :token_url, :version, :sync_id, :access_token, :refresh_token, :token_expires_at

      def initialize(client_id: nil, client_secret: nil, version: nil,
        sync_id: nil, access_token: nil, refresh_token: nil,
        token_expires_at: nil, prod: true, filepath: nil)
        domain = (prod ? "agxplatform.com" : "qaagxplatform.com")
        @client_id = client_id || ENV['AGX_SYNC_CLIENT_ID']
        @client_secret = client_secret || ENV['AGX_SYNC_CLIENT_SECRET']
        @site = "https://pictures.#{domain}"
        @host = host || "pictures.#{domain}"
        @authorize_url = "https://auth.#{domain}/identity/connect/Authorize"
        @token_url = "https://auth.#{domain}/identity/connect/Token"
        @version = version || "v1"
        @sync_id = sync_id
        @api_url = "#{@site}/api/#{@version}/picture/"
        @filepath = filepath
        @headers = {
          'oauth-scopes' => "Sync",
          'Host' => @host
        }
        @client = set_client
        @token = {
          access_token: access_token,
          refresh_token: refresh_token,
          expires_at: token_expires_at
        }
      end

      def get(id)
        url = "#{@api_url}#{id}"
        begin
          response = current_token.get(url, :headers => @headers)
          filename = "#{@filepath}/#{@sync_id}_#{id}.jpeg"
          File.open(filename, 'wb') { |fp| fp.write(response.body) }
        rescue => e
          handle_error(e)
        end
      end

      def get_metadata(id)
        url = "#{@api_url}#{id}/metadata"
        begin
          response = current_token.get(url, :headers => @headers)
          parse_response(response.body)
        rescue => e
          handle_error(e)
        end
      end

      protected

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
        new_token = OAuth2::AccessToken.new @client, @token[:access_token], {
          expires_at: @token[:expires_at],
          refresh_token: @token[:refresh_token]
        }
        if Time.now.to_i + 90 >= @token[:expires_at]
          new_token = new_token.refresh!
          @token[:access_token] = new_token.token
          @token[:refresh_token] = new_token.refresh_token
          @token[:expires_at] = new_token.expires_at
        end

        new_token
      end

      def set_client
        @client = OAuth2::Client.new(
          @client_id,
          @client_secret, {
            site: @site,
            authorize_url: @authorize_url,
            token_url: @token_url,
            options: {
              ssl: { ca_path: "/usr/lib/ssl/certs" }
            }
          }
        )
      end

    end
  end
end
