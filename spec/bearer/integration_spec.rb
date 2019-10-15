# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Bearer::Integration do
  subject(:client) do
    described_class.new(
      host: host,
      integration_id: integration_id,
      secret_key: secret_key
    )
  end

  let(:host) { "https://int.example.com" }
  let(:integration_id) { "test-integration-id" }
  let(:secret_key) { "test-api-key" }

  let(:base_url) { "https://int.example.com/#{integration_id}" }
  let(:headers) do
    {
      "Accept" => "*/*",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Authorization" => "test-api-key",
      "Content-Type" => "application/json",
      "Host" => "int.example.com",
      "User-Agent" => "Bearer-Ruby (#{Bearer::VERSION})"
    }
  end

  let(:success_payload) { { "data" => "It Works!!" } }
  let(:success_response) { success_payload.to_json }
  let(:success_headers) { { "Bearer-Request-Id" => "bearer-request-id" } }
  let(:body_payload) { { body: "data" } }
  let(:body) { body_payload.to_json }

  context "making requests" do
    let(:proxy_url) { "#{base_url}/test" }
    let(:endpoint) { "/test" }

    let(:query) {}
    let(:sent_headers) do
      {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Authorization" => secret_key,
        "Host" => "int.example.com",
        "User-Agent" => "Bearer-Ruby (#{Bearer::VERSION})",
      }
    end

    let(:headers) { { "test" => "header" } }

    describe "#get" do
      it "makes a request to the proxy function", :aggregate_failures do
        stub_request(:get, proxy_url)
          .with(headers: sent_headers, query: query)
          .to_return(status: 200, body: success_response, headers: success_headers)

        expect(Bearer.logger).to receive(:info).with("Bearer")

        response = client.get("/test", headers: headers, query: query)

        expect(JSON.parse(response.body)).to eq(success_payload)
      end
    end

    describe "#head" do
      it "makes a request to the proxy function" do
        stub_request(:head, proxy_url)
          .with(headers: sent_headers.reject { |k| k == "Accept-Encoding" }, query: query)
          .to_return(status: 200)

        response = client.head("/test", headers: headers, query: query)

        expect(response.code).to eq("200")
      end
    end

    describe "#post" do
      it "makes a request to the proxy function" do
        stub_request(:post, proxy_url)
          .with(headers: sent_headers, query: query, body: body)
          .to_return(status: 200, body: success_response)

        response = client.post("/test", headers: headers, query: query, body: body_payload)

        expect(JSON.parse(response.body)).to eq(success_payload)
      end
    end

    describe "#put" do
      it "makes a request to the proxy function" do
        stub_request(:put, proxy_url)
          .with(headers: sent_headers, query: query, body: body)
          .to_return(status: 200, body: success_response)

        response = client.put("/test", headers: headers, query: query, body: body_payload)

        expect(JSON.parse(response.body)).to eq(success_payload)
      end
    end

    describe "#patch" do
      it "makes a request to the proxy function" do
        stub_request(:patch, proxy_url)
          .with(headers: sent_headers, query: query, body: body)
          .to_return(status: 200, body: success_response)

        response = client.patch("/test", headers: headers, query: query, body: body_payload)

        expect(JSON.parse(response.body)).to eq(success_payload)
      end
    end

    describe "#delete" do
      it "makes a request to the proxy function" do
        stub_request(:delete, proxy_url)
          .with(headers: sent_headers, query: query, body: body)
          .to_return(status: 200, body: success_response)

        response = client.delete("/test", headers: headers, query: query, body: body_payload)

        expect(JSON.parse(response.body)).to eq(success_payload)
      end
    end

    describe "#auth" do
      let(:auth_id) { "test-auth-id" }
      let(:auth_sent_headers) { sent_headers.merge("Bearer-Auth-Id" => auth_id) }

      it "sends the auth id in the Bearer-Auth-Id header" do
        stub_request(:get, proxy_url).with(headers: auth_sent_headers).to_return(status: 200)

        response = client.auth(auth_id).get("/test", headers: headers)

        expect(response.code).to eq("200")
      end
    end

    describe "#setup" do
      let(:setup_id) { "test-setup-id" }
      let(:setup_sent_headers) { sent_headers.merge("Bearer-Setup-Id" => setup_id) }

      it "sends the setup id in the Bearer-Setup-Id header" do
        stub_request(:get, proxy_url).with(headers: setup_sent_headers).to_return(status: 200)

        response = client.setup(setup_id).get("/test", headers: headers)

        expect(response.code).to eq("200")
      end
    end
  end

  describe "setting http client per integration" do
    subject(:client) do
      described_class.new(
        host: host,
        integration_id: integration_id,
        secret_key: secret_key,
        http_client_settings: { read_timeout: 1 }
      )
    end

    before do
      stub_request(:get, "https://int.example.com/test-integration-id/test")
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "test-api-key",
            "Content-Type" => "application/json",
            "Host" => "int.example.com",
            "User-Agent" => "Bearer-Ruby (#{Bearer::VERSION})"
          }
        )
        .to_return(status: 200, body: "", headers: {})
    end
    it "respects http client integration settings" do
      expect(Net::HTTP).to receive(:start).with("int.example.com", 443, open_timeout: 5, read_timeout: 1, use_ssl: true)
      client.get("/test")
    end
  end
end
