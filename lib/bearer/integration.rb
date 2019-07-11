# frozen_string_literal: true

require "net/http"
require "json"

require_relative "./errors"
require_relative "./version"

class Bearer
  class Integration
    FUNCTIONS_PATH = "api/v4/functions/backend"
    PROXY_FUNCTION_NAME = "bearer-proxy"

    def initialize(
      integration_id:,
      integration_host:,
      api_key:,
      setup_id: nil,
      auth_id: nil
    )
      @integration_id = integration_id
      @integration_host = integration_host
      @api_key = api_key
      @setup_id = setup_id
      @auth_id = auth_id
    end

    # Public: Invoke an integration function
    #
    # function_name    - function to invoke
    # body             - data to pass in the body of the request
    # query            - parameters to pass in the query string of the request
    #
    # Returns the response from the function
    def invoke(function_name, body: nil, query: nil)
      url = "#{@integration_host}/#{FUNCTIONS_PATH}/#{@integration_id}/#{function_name}"
      headers = {
        "Content-Type" => "application/json",
        "Authorization": @api_key,
        "User-Agent" => "Bearer (#{Bearer::VERSION})"
      }

      response = make_request(method: "POST", url: url, query: query, body: body, headers: headers)

      JSON.parse(response.body).tap do |response_data|
        raise Errors::FunctionError, response_data["error"] if response_data["error"]
      end
    end

    # Public: Returns a new integration client instance that will use the given setup id for requests
    #
    # setup_id - the setup id from the dashboard
    def setup(setup_id)
      self.class.new(
        integration_id: @integration_id,
        integration_host: @integration_host,
        api_key: @api_key,
        setup_id: setup_id,
        auth_id: @auth_id
      )
    end

    # Public: Returns a new integration client instance that will use the given auth id for requests
    #
    # auth_id - the auth id used to connect
    def auth(auth_id)
      self.class.new(
        integration_id: @integration_id,
        integration_host: @integration_host,
        api_key: @api_key,
        setup_id: @setup_id,
        auth_id: auth_id
      )
    end

    # Public: An alias for `#auth`
    def authenticate(auth_id)
      auth(auth_id)
    end

    # Public: Makes a GET request to the API configured for this integration and returns the response
    #
    # See `self.request` for a description of the parameters
    def get(endpoint, headers: nil, body: nil, query: nil)
      request("GET", endpoint, headers: headers, body: body, query: query)
    end

    # Public: Makes a GET request to the API configured for this integration and returns the response
    #
    # See `self.request` for a description of the parameters
    def head(endpoint, headers: nil, body: nil, query: nil)
      request("HEAD", endpoint, headers: headers, body: body, query: query)
    end

    # Public: Makes a GET request to the API configured for this integration and returns the response
    #
    # See `self.request` for a description of the parameters
    def post(endpoint, headers: nil, body: nil, query: nil)
      request("POST", endpoint, headers: headers, body: body, query: query)
    end

    # Public: Makes a GET request to the API configured for this integration and returns the response
    #
    # See `self.request` for a description of the parameters
    def put(endpoint, headers: nil, body: nil, query: nil)
      request("PUT", endpoint, headers: headers, body: body, query: query)
    end

    # Public: Makes a GET request to the API configured for this integration and returns the response
    #
    # See `self.request` for a description of the parameters
    def patch(endpoint, headers: nil, body: nil, query: nil)
      request("PATCH", endpoint, headers: headers, body: body, query: query)
    end

    # Public: Makes a GET request to the API configured for this integration and returns the response
    #
    # See `self.request` for a description of the parameters
    def delete(endpoint, headers: nil, body: nil, query: nil)
      request("DELETE", endpoint, headers: headers, body: body, query: query)
    end

    # Public: Makes a request to the API configured for this integration and returns the response

    # method   - GET/HEAD/POST/PUT/PATCH/DELETE
    # endpoint - the URL relative to the configured API's base URL
    # headers  - any headers to send to the API
    # body     - any request body data to send
    # query    - parameters to add to the URL's query string
    def request(method, endpoint, headers: nil, body: nil, query: nil)
      pre_headers = {
        "Authorization": @api_key,
        "User-Agent": "Bearer.sh",
        "Bearer-Auth-Id": @auth_id,
        "Bearer-Setup-Id": @setup_id,
        # TODO: Remove this when integration service content type support is fixed
        "Content-Type": "application/json"
      }

      headers&.each do |key, value|
        pre_headers["Bearer-Proxy-#{key}"] = value
      end

      request_headers = pre_headers.reject { |_k, v| v.nil? }
      endpoint = endpoint.sub(%r{\A/}, "")
      url = "#{@integration_host}/#{FUNCTIONS_PATH}/#{@integration_id}/#{PROXY_FUNCTION_NAME}/#{endpoint}"

      make_request(method: method, url: url, query: query, body: body, headers: request_headers)
    end

    private

    def make_request(method:, url:, query:, body:, headers:)
      parsed_url = URI(url)
      parsed_url.query = URI.encode_www_form(query) if query

      Net::HTTP.start(parsed_url.hostname, parsed_url.port, use_ssl: parsed_url.scheme == "https") do |http|
        http.send_request(method, parsed_url, body ? body.to_json : nil, headers)
      end
    end
  end
end
