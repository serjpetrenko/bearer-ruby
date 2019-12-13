# frozen_string_literal: true

class Bearer
  # Bearer::Response encapsulates some vitals of a response that came back from
  # the bearer proxy.
  class Response
    # Headers provides an access wrapper to an API response's header data. It
    # mainly exists so that we don't need to expose the entire
    # `Net::HTTPResponse` object while still getting some of its benefits like
    # case-insensitive access to header names and flattening of header values.
    class Headers
      # Initializes a Headers object from a Net::HTTP::HTTPResponse object.
      def self.from_net_http(resp)
        new(resp.to_hash)
      end

      # `hash` is expected to be a hash mapping header names to arrays of
      # header values. This is the default format generated by calling
      # `#to_hash` on a `Net::HTTPResponse` object because headers can be
      # repeated multiple times. Using `#[]` will collapse values down to just
      # the first.
      def initialize(hash)
        if !hash.is_a?(Hash) ||
           !hash.keys.all? { |n| n.is_a?(String) } ||
           !hash.values.all? { |a| a.is_a?(Array) } ||
           !hash.values.all? { |a| a.all? { |v| v.is_a?(String) } }
          raise ArgumentError,
                "expect hash to be a map of string header names to arrays of " \
                "header values"
        end

        @hash = {}

        # This shouldn't be strictly necessary because `Net::HTTPResponse` will
        # produce a hash with all headers downcased, but do it anyway just in
        # case an object of this class was constructed manually.
        #
        # Also has the effect of duplicating the hash, which is desirable for a
        # little extra object safety.
        hash.each do |k, v|
          @hash[k.downcase] = v
        end
      end

      def [](name)
        values = @hash[name.downcase]
        warn("Duplicate header values for `#{name}`; returning only first") if values && values.count > 1
        values ? values.first : nil
      end
    end

    # The data contained by the HTTP body of the response deserialized from
    # JSON.
    attr_accessor :data

    # The raw HTTP body of the response.
    attr_accessor :http_body

    # A Hash of the HTTP headers of the response.
    attr_accessor :http_headers

    # The integer HTTP status code of the response.
    attr_accessor :http_status

    # The Bearer request ID of the response.
    attr_accessor :request_id

    # Initializes a Bearer::Response object from a Net::HTTP::HTTPResponse
    # object.
    def self.from_net_http(http_resp)
      resp = Bearer::Response.new
      begin
        resp.data = JSON.parse(http_resp.body, symbolize_names: true)
      rescue JSON::ParserError => _e
        resp.data = "response body is not JSON parsable"
      end
      resp.http_body = http_resp.body
      resp.http_headers = Headers.from_net_http(http_resp)
      resp.http_status = http_resp.code.to_i
      resp.request_id = http_resp["bearer-request-id"]
      resp
    end
  end
end
