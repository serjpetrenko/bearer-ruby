require "webmock/rspec"

RSpec.describe Bearer::Integration do
  subject(:client) do
    described_class.new(
      integration_host: integration_host,
      integration_id: integration_id,
      api_key: api_key,
    )
  end

  let(:integration_host) { "https://int.example.com" }
  let(:integration_id) { "test-integration-id" }
  let(:api_key) { "test-api-key" }

  let(:base_url) { "https://int.example.com/api/v4/functions/backend/#{integration_id}" }
  let(:headers) do
    {
      "Accept" => "*/*",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Authorization" => "test-api-key",
      "Content-Type" => "application/json",
      "Host" => "int.example.com",
      "User-Agent" => "Bearer (0.2.0)"
    }
  end

  let(:success_payload) { {"data" => "It Works!!"} }
  let(:success_response) { success_payload.to_json }
  let(:body_payload) { { body: "data" } }
  let(:body) { body_payload.to_json }

  describe "#invoke" do
    it "makes a request to the function and returns the response" do
      query = { q: "dolly" }

      stub_request(:post, "#{base_url}/fetch-goats")
        .with(body: body, headers: headers, query: query)
        .to_return(status: 200, body: success_response)

      response = client.invoke("fetch-goats", query: query, body: body_payload)

      expect(response).to eq(success_payload)
    end

    it "throws a FunctionError if the function has an error response" do
      error_json = '{"message":"Oh no!"}'

      stub_request(:post, "#{base_url}/error")
        .with(headers: headers)
        .to_return(status: 200, body: %({"error":#{error_json}}))

      expect { client.invoke("error") }.to raise_error(Bearer::Errors::FunctionError, error_json) do |error|
        expect(error.data).to eq("message" => "Oh no!")
      end
    end
  end

  context "making requests" do
    let(:proxy_url) { "#{base_url}/bearer-proxy/test" }
    let(:endpoint) { "/test" }

    let(:query) {  }
    let(:sent_headers) do
      {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Authorization" => api_key,
        "Host" => "int.example.com",
        # FIXME: We try to set this but it isn't working
        "User-Agent" => "Ruby",
        "Bearer-Proxy-test" => "header"
      }
    end

    let(:headers) { { "test" => "header" } }

    describe "#get" do
      it "makes a request to the proxy function" do
        stub_request(:get, proxy_url)
          .with(headers: sent_headers, query: query)
          .to_return(status: 200, body: success_response)

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

      it "sends the auth id in the Bearer-Auth-Id header" do
        stub_request(:get, proxy_url).with(headers: setup_sent_headers).to_return(status: 200)

        response = client.setup(setup_id).get("/test", headers: headers)

        expect(response.code).to eq("200")
      end
    end
  end
end
