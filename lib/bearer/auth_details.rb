# frozen_string_literal: true

class Bearer
  class AuthDetails
    module OAuth1SignatureMethod
      HMAC_SHA1 = "HMAC-SHA1"
      RSA_SHA1 = "RSA-SHA1"
      PLAIN_TEXT = "PLAINTEXT"
    end

    module TokenType
      OAUTH1 = "oauth"
      OAUTH2_ACCESS_TOKEN = "bearer"
      OAUTH2_REFRESH_TOKEN = "refresh" # Not defined in RFC7662
      OPENID_CONNECT = "id" # Not defined in RFC7662
    end

    TokenResponse = Struct.new(:body, :headers)

    class TokenData
      attr_reader :client_id,
                  :expires_at,
                  :issued_at,
                  :scopes,
                  :token_type,
                  :value

      def initialize(raw_data)
        expect_scopes = [
          TokenType::OAUTH2_ACCESS_TOKEN,
          TokenType::OAUTH2_REFRESH_TOKEN
        ].include?(raw_data[:token_type])

        @active = raw_data[:active]
        @client_id = raw_data[:client_id]
        @expires_at = raw_data[:exp] && Time.at(raw_data[:exp]).utc
        @issued_at = Time.at(raw_data[:iat]).utc
        @scopes =
          if raw_data[:scope]
            raw_data[:scope].split(" ")
          else
            expect_scopes ? [] : nil
          end
        @token_type = raw_data[:token_type]
        @value = raw_data[:value]
      end

      def active?
        @active
      end
    end

    attr_reader :access_token,
                :callback_params,
                :client_id,
                :client_secret,
                :consumer_key,
                :consumer_secret,
                :id_token,
                :id_token_jwt,
                :raw_data,
                :refresh_token,
                :token_response,
                :token_secret,
                :signature_method

    # rubocop:disable Metrics/AbcSize
    def initialize(raw_data)
      @access_token = TokenData.new(raw_data[:accessToken])
      @callback_params = raw_data[:callbackParams]
      @client_id = raw_data[:clientID]
      @client_secret = raw_data[:clientSecret]
      @consumer_key = raw_data[:consumerKey]
      @consumer_secret = raw_data[:consumerSecret]
      @id_token = raw_data[:idToken] && TokenData.new(raw_data[:idToken])
      @id_token_jwt = raw_data[:idTokenJwt]
      @raw_data = raw_data
      @refresh_token = raw_data[:refreshToken] && TokenData.new(raw_data[:refreshToken])
      @token_response = TokenResponse.new(raw_data[:tokenResponse][:body], raw_data[:tokenResponse][:headers])
      @token_secret = raw_data[:tokenSecret]
      @signature_method = raw_data[:signatureMethod]
    end
    # rubocop:enable Metrics/AbcSize
  end
end
