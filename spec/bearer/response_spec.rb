# frozen_string_literal: true

require "spec_helper"

RSpec.describe Bearer::Response do
  context "Headers" do
    it "allow case-insensitive header access" do
      headers = { "Request-Id" => "request-id" }
      http_resp = create_net_http_resp(200, "", headers)

      headers = Bearer::Response::Headers.from_net_http(http_resp)

      expect(headers["request-id"]).to eq  "request-id"
      expect(headers["Request-Id"]).to eq  "request-id"
      expect(headers["Request-ID"]).to eq  "request-id"
    end

    it "initialize without error" do
      Bearer::Response::Headers.new({})
      Bearer::Response::Headers.new("Request-Id" => [])
      Bearer::Response::Headers.new("Request-Id" => ["request-id"])
    end

    it "initialize with error on a malformed hash" do
      expect { Bearer::Response::Headers.new(nil) }.to raise_error(ArgumentError)

      expect { Bearer::Response::Headers.new(1 => []) }.to raise_error(ArgumentError)

      expect { Bearer::Response::Headers.new("Request-Id" => 1) }.to raise_error(ArgumentError)

      expect { Bearer::Response::Headers.new("Request-Id" => [1]) }.to raise_error(ArgumentError)
    end

    it "warn on duplicate header values" do
      old_stderr = $stderr
      $stderr = StringIO.new
      begin
        headers = Bearer::Response::Headers.new("Duplicated" => %w[a b])
        expect(headers["Duplicated"]).to eq "a"
        expect($stderr.string.rstrip).to eq "Duplicate header values for `Duplicated`; returning only first"

      ensure
        $stderr = old_stderr
      end
    end
  end

  context ".from_net_http" do
    it "converts to Bearer::Response" do
      code = 200
      body = '{"foo": "bar"}'
      headers = { "Bearer-Request-Id" => "request-id" }
      http_resp = create_net_http_resp(code, body, headers)

      resp = Bearer::Response.from_net_http(http_resp)

      expect(resp.data).to eq JSON.parse(body, symbolize_names: true)
      expect(resp.http_body).to eq body
      expect(resp.http_headers["Bearer-Request-ID"]).to eq "request-id"
      expect(resp.http_status).to eq code
      expect(resp.request_id).to eq "request-id"
    end
  end

  # Synthesizes a `Net::HTTPResponse` object for testing purposes.
  private def create_net_http_resp(code, body, headers)
    # The "1.1" is HTTP version.
    http_resp = Net::HTTPResponse.new("1.1", code.to_s, nil)
    http_resp.body = body

    # This is obviously super sketchy, but the Ruby team has done everything
    # in their power to make these objects as difficult to test with as
    # possible. Even if you specify a body, accessing `#body` the first time
    # will attempt to read from a non-existent socket which will subsequently
    # blow up. Setting this internal variable skips that read and allows the
    # object to use the body that we specified above.
    http_resp.instance_variable_set(:@read, true)

    headers.each do |name, value|
      http_resp[name] = value
    end

    http_resp
  end
end
