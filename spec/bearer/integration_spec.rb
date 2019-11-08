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

  let(:success_payload) { { data: "It Works!!" } }
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
        "User-Agent" => "Bearer-Ruby (#{Bearer::VERSION})"
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

        expect(response.data).to eq(success_payload)
      end
    end

    describe "#head" do
      it "makes a request to the proxy function" do
        stub_request(:head, proxy_url)
          .with(headers: sent_headers.reject { |k| k == "Accept-Encoding" }, query: query)
          .to_return(status: 200, body: "{}")

        response = client.head("/test", headers: headers, query: query)

        expect(response.http_status).to eq(200)
      end
    end

    describe "#post" do
      it "makes a request to the proxy function" do
        stub_request(:post, proxy_url)
          .with(headers: sent_headers, query: query, body: body)
          .to_return(status: 200, body: success_response)

        response = client.post("/test", headers: headers, query: query, body: body_payload)

        expect(response.data).to eq(success_payload)
      end
    end

    describe "#put" do
      it "makes a request to the proxy function" do
        stub_request(:put, proxy_url)
          .with(headers: sent_headers, query: query, body: body)
          .to_return(status: 200, body: success_response)

        response = client.put("/test", headers: headers, query: query, body: body_payload)

        expect(response.data).to eq(success_payload)
      end
    end

    describe "#patch" do
      it "makes a request to the proxy function" do
        stub_request(:patch, proxy_url)
          .with(headers: sent_headers, query: query, body: body)
          .to_return(status: 200, body: success_response)

        response = client.patch("/test", headers: headers, query: query, body: body_payload)

        expect(response.data).to eq(success_payload)
      end
    end

    describe "#delete" do
      it "makes a request to the proxy function" do
        stub_request(:delete, proxy_url)
          .with(headers: sent_headers, query: query, body: body)
          .to_return(status: 200, body: success_response)

        response = client.delete("/test", headers: headers, query: query, body: body_payload)

        expect(response.data).to eq(success_payload)
      end
    end

    describe "#auth" do
      let(:auth_id) { "test-auth-id" }
      let(:auth_sent_headers) { sent_headers.merge("Bearer-Auth-Id" => auth_id) }

      it "sends the auth id in the Bearer-Auth-Id header" do
        stub_request(:get, proxy_url).with(headers: auth_sent_headers).to_return(status: 200, body: "{}")

        response = client.auth(auth_id).get("/test", headers: headers)

        expect(response.http_status).to eq(200)
      end
    end

    describe "#setup" do
      let(:setup_id) { "test-setup-id" }
      let(:setup_sent_headers) { sent_headers.merge("Bearer-Setup-Id" => setup_id) }

      it "sends the setup id in the Bearer-Setup-Id header" do
        stub_request(:get, proxy_url).with(headers: setup_sent_headers).to_return(status: 200, body: "{}")

        response = client.setup(setup_id).get("/test", headers: headers)

        expect(response.http_status).to eq(200)
      end
    end

    describe "retrying requests" do
      around(:each) do |example|
        old_max_network_retries = Bearer::Configuration.max_network_retries
        Bearer::Configuration.max_network_retries = 2
        example.run
        Bearer::Configuration.max_network_retries = old_max_network_retries
      end
      it "retries the request and raises (by default a single retry is made)", :aggregate_failures do
        stub_request(:get, proxy_url)
          .with(headers: sent_headers, query: query)
          .to_timeout


        # 3 times is first attempt + 2 retries
        expect(Net::HTTP).to receive(:start).exactly(3).times.and_call_original
        # 4 warnings -> 3 warnings informing about an error + 4th warning about num_retries exceeded
        expect(Bearer.logger).to receive(:warn).exactly(4).times.with("Bearer")
        expect { client.get("/test", headers: headers, query: query) }.to raise_error(Net::OpenTimeout)
      end

      it "retries the request and succeeds" do
        stub_request(:get, proxy_url)
          .with(headers: sent_headers, query: query)
          .to_timeout.then
          .to_return(status: 200, body: success_response)

        response = client.get("/test", headers: headers, query: query)

        expect(response.http_body).to eq(success_response)
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

    let(:mock_response) { double(body: "{}", header: {}, code: 1, to_hash: {}, "[]": nil) }

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
        .to_return(status: 200, body: "{}", headers: {})
    end
    it "respects http client integration settings" do
      expect(Net::HTTP).to receive(:start).with("int.example.com", 443, open_timeout: 5, read_timeout: 1, use_ssl: true) { mock_response }
      client.get("/test")
    end
  end

  describe ".sleep_time" do
    subject(:sleep_time) do
      lambda do |n|
        Bearer::Integration.sleep_time(n)
      end
    end

    it "provides reasonable sleep_time defaults", :aggregate_failures do
      expect(sleep_time[0]).to eq 0.5
      expect(sleep_time[1]).to eq 0.5
    end
  end

  describe ".should_retry?" do
    let (:max_network_retries) { 3 }
    before do
      Bearer::Configuration.max_network_retries = max_network_retries
    end
    subject(:should_retry?) do
      lambda do |error, num_retries|
        Bearer::Integration.should_retry? error, num_retries: num_retries
      end
    end

    it "is false when num_retries > max_network_retries" do
      expect(should_retry?[StandardError.new, max_network_retries + 1]).to eq false
    end

    context "when num_retries < max_network_retries" do
      [
        Net::OpenTimeout,
        Net::ReadTimeout,
        EOFError,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::ETIMEDOUT,
        SocketError
      ].each do |e|
        it "is true for #{e.name}" do
          expect(should_retry?[e.new, 0]).to eq true
        end
      end
    end
  end
end
