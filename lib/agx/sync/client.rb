module Agx
  module Sync
    class Client
      attr_accessor :client_id, :client_secret, :site, :host, :authorize_url,
        :token_url, :version, :sync_id, :access_token, :refresh_token, :token_expires_at,
        :transaction_id

      def initialize(client_id: nil, client_secret: nil, site: nil, host: nil,
        authorize_url: nil, token_url: nil, version: nil, sync_id: nil,
        access_token: nil, refresh_token: nil, token_expires_at: nil,
        transaction_id: nil)
        @client_id = client_id || ENV['AGX_SYNC_CLIENT_ID']
        @client_secret = client_secret || ENV['AGX_SYNC_CLIENT_SECRET']
        @site = site || "https://sync.agxplatform.com"
        @host = host || "sync.agxplatform.com"
        @authorize_url = authorize_url || "https://auth.agxplatform.com/Account/Authorize"
        @token_url = token_url || "https://auth.agxplatform.com/Account/Token"
        @version = version || "v3"
        @sync_id = sync_id
        @api_url = "#{@site}/api/#{@version}/Account/#{@sync_id}/"
        @headers = {
          'Content-Type' => "application/json",
          'Accept' => "application/json",
          'oauth-scopes' => "Sync",
          'Host' => @host
        }
        @client = set_client
        @token = {
          access_token: access_token,
          refresh_token: refresh_token,
          expires_at: token_expires_at
        }
        @transaction_id = transaction_id
      end

      def retrieve(resource, start_time = nil)
        url = "#{@api_url}#{resource}?transactionId=#{@transaction_id}"
        if !start_time.nil?
          url = "#{@api_url}#{resource}?startTime=#{start_time}&transactionId=#{@transaction_id}"
        end
        begin
          request = current_token.get(url, :headers => @headers)
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

      def start_transaction
        if !@transaction_id.nil?
          end_transaction
        end
        begin
          transaction_request = current_token.get(
            "#{@api_url}Transaction",
            :headers => @headers
          )
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
          @transaction_id = Oj.load(transaction_request.body)
          api_response = {
            'status': request.response.status,
            'message': nil,
            'body': @transaction_id
          }
          return api_response
        end
      end

      def end_transaction
        begin
          end_transaction_request = current_token.delete(
            "#{@api_url}Transaction/#{@transaction_id}",
            :headers => @headers
          )
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
            'body': true
          }
          return api_response
        end
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
        return new_token
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
