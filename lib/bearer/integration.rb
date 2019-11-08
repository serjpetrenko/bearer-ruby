# frozen_string_literal: true

require "net/http"
require "json"

require_relative "./errors"
require_relative "./version"

class Bearer
  class Integration
    # @param integration_id [String] integration id
    # @param host [String] "https://proxy.bearer.sh" | "https://proxy.staging.bearer.sh"
    # @param http_client_settings [Hash<String,String>] http client settings see Net::HTTP#start
    # @param auth_id [String] the auth id used to connect
    # @param setup_id [String] the setup id used to store the credentials
    # @param @deprecated read_timeout [String] use http_client_settings instead
    def initialize(
      integration_id:,
      host:,
      secret_key:,
      http_client_settings: {},
      read_timeout: nil,
      auth_id: nil,
      setup_id: nil
    )
      @integration_id = integration_id
      @host = host
      @secret_key = secret_key
      @auth_id = auth_id
      @read_timeout = read_timeout
      @http_client_settings = http_client_settings
      @setup_id = setup_id
    end

    # Returns a new integration client instance that will use the given auth id for requests
    # @param auth_id [String] the auth id used to connect
    # @return [Bearer::Integration]
    def auth(auth_id)
      self.class.new(
        integration_id: @integration_id,
        host: @host,
        secret_key: @secret_key,
        auth_id: auth_id
      )
    end

    # Returns a new integration client instance that will use the given setup id for requests
    # @param setup_id [String] uuid setup id used to store credentials
    # @return [Bearer::Integration]
    def setup(setup_id)
      self.class.new(
        integration_id: @integration_id,
        host: @host,
        secret_key: @secret_key,
        setup_id: setup_id,
        auth_id: @auth_id
      )
    end

    # An alias for `#auth`
    # @see {#auth}
    def authenticate(auth_id)
      auth(auth_id)
    end

    # Makes a HEAD request to the API configured for this integration and returns the response
    # @param (see #request)
    def get(endpoint, headers: nil, body: nil, query: nil)
      request("GET", endpoint, headers: headers, body: body, query: query)
    end

    # Makes a HEAD request to the API configured for this integration and returns the response
    # @param (see #request)
    def head(endpoint, headers: nil, body: nil, query: nil)
      request("HEAD", endpoint, headers: headers, body: body, query: query)
    end

    # Makes a POST request to the API configured for this integration and returns the response
    # @param (see #request)
    def post(endpoint, headers: nil, body: nil, query: nil)
      request("POST", endpoint, headers: headers, body: body, query: query)
    end

    # Makes a PUT request to the API configured for this integration and returns the response
    # @param (see #request)
    def put(endpoint, headers: nil, body: nil, query: nil)
      request("PUT", endpoint, headers: headers, body: body, query: query)
    end

    # Makes a GET request to the API configured for this integration and returns the response
    # @param (see #request)
    def patch(endpoint, headers: nil, body: nil, query: nil)
      request("PATCH", endpoint, headers: headers, body: body, query: query)
    end

    # Makes a DELETE request to the API configured for this integration and returns the response
    # @param (see #request)
    def delete(endpoint, headers: nil, body: nil, query: nil)
      request("DELETE", endpoint, headers: headers, body: body, query: query)
    end

    # Makes a request to the API configured for this integration and returns the response
    # @param method [String] GET/HEAD/POST/PUT/PATCH/DELETE
    # @param endpoint [String] the URL relative to the configured API's base URL
    # @param headers [Hash<String, String>] any headers to send to the API
    # @param body [Hash] any request body data to send
    # @param query [Hash<String, String>] parameters to add to the URL's query string
    def request(method, endpoint, headers: nil, body: nil, query: nil)
      pre_headers = {
        "Authorization": @secret_key,
        "User-Agent": "Bearer-Ruby (#{Bearer::VERSION})",
        "Bearer-Auth-Id": @auth_id,
        "Bearer-Setup-Id": @setup_id,
        "Content-Type": "application/json"
      }

      request_headers = pre_headers.merge(headers || {}).reject { |_k, v| v.nil? }

      endpoint = endpoint.sub(%r{\A/}, "")
      url = "#{@host}/#{@integration_id}/#{endpoint}"

      make_request(method: method, url: url, query: query, body: body, headers: request_headers)
    end

    # Checks if an error is a problem that we should retry on. This includes
    # both socket errors that may represent an intermittent problem and some
    # special HTTP statuses.
    # TODO: handle bearer errors like 500 statuses
    def self.should_retry?(error, num_retries:)
      return false if num_retries >= Bearer::Configuration.max_network_retries

      case error
      when Net::OpenTimeout, Net::ReadTimeout
        # Retry on timeout-related problems (either on open or read).
        true
      when EOFError, Errno::ECONNREFUSED, Errno::ECONNRESET,
            Errno::EHOSTUNREACH, Errno::ETIMEDOUT, SocketError
        # Destination refused the connection, the connection was reset, or a
        # variety of other connection failures. This could occur from a single
        # saturated server, so retry in case it's intermittent.
        true
      else
        false
      end
    end

    def self.sleep_time(num_retries)
      # Apply exponential backoff with initial_network_retry_delay on the
      # number of num_retries so far as inputs. Do not allow the number to
      # exceed max_network_retry_delay.
      sleep_seconds = [
        Bearer::Configuration.initial_network_retry_delay * (2**(num_retries - 1)),
        Bearer::Configuration.max_network_retry_delay
      ].min

      # Apply some jitter by randomizing the value in the range of
      # (sleep_seconds / 2) to (sleep_seconds).
      sleep_seconds *= (0.5 * (1 + rand))

      # But never sleep less than the base sleep seconds.
      sleep_seconds = [Bearer::Configuration.initial_network_retry_delay, sleep_seconds].max

      sleep_seconds
    end

    private

    # @return [Hash]
    def http_client_settings
      Bearer::Configuration.http_client_settings.merge(@http_client_settings)
    end

    # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    def make_request(method:, url:, query:, body:, headers:)
      num_retries = 0
      parsed_url = URI(url)
      parsed_url.query = URI.encode_www_form(query) if query

      debug_request(parsed_url: parsed_url,
                    http_client_settings: http_client_settings,
                    method: method,
                    body: body,
                    headers: headers)
      begin
        response = Net::HTTP.start(
          parsed_url.hostname,
          parsed_url.port,
          use_ssl: parsed_url.scheme == "https",
          **http_client_settings
        ) do |http|
          http.send_request(method, parsed_url, body ? body.to_json : nil, headers)
        end.tap(&info_response)

        Bearer::Response.from_net_http(response)
      rescue StandardError => e
        Bearer.logger.warn("Bearer") do
          <<-WARN.gsub(/^\s+/, "")
               There was an error while trying to make a request to bearer.
               #{e.class.name}: #{e.message}
          WARN
        end
        if self.class.should_retry?(e, num_retries: num_retries)
          num_retries += 1
          Bearer.logger.info("Bearer") { "retrying request" }
          retry
        else
          Bearer.logger.warn("Bearer") do
            "Failed to perform to bearer request number of retries exceeded"
          end
          raise e
        end
      end
    end
    # rubocop:enable Metrics/MethodLength,Metrics/AbcSize

    # @return [void]
    def debug_request(parsed_url:, http_client_settings:, method:, body:, headers:)
      Bearer.logger.debug("Bearer") do
        <<-DEBUG.gsub(/^\s+/, "")
          sending request
            hostname: #{parsed_url.hostname}
            port: #{parsed_url.port}
            scheme: #{parsed_url.scheme}
            method: #{method}
            http_client_settings: #{http_client_settings.to_json}
            body: #{body ? body.to_json : ''}
            headers: #{headers ? headers.to_json : ''}
        DEBUG
      end
    end

    # @return [void]
    def info_response
      lambda do |response|
        return unless response

        Bearer.logger.info("Bearer") do
          <<-INFO.gsub(/^\s+/, "")
            response requestId: #{response.header['bearer-request-id']}
          INFO
        end
      end
    end
  end
end
