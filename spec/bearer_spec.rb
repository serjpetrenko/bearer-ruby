# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Bearer do
  it "has a version number" do
    expect(Bearer::VERSION).not_to be nil
  end

  let(:mock_response) { double(body: "{}", header: {}, code: 1, to_hash: {}, :"[]" => nil) }
  describe "#integration" do
    before do
      stub_request(:get, "http://some.host.com/api/v4/functions/backend/github/bearer-proxy/user/repos")
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "sk_production_...",
            "Content-Type" => "application/json",
            "Host" => "some.host.com",
            "User-Agent" => "Bearer-Ruby (#{Bearer::VERSION})"
          }
        ).to_return(status: 200, body: "", headers: {})
    end
    it "allows to setup integration correctly", :aggregate_failures do
      Bearer::Configuration.setup do |config|
        config.host = "http://some.host.com"
        config.secret_key = "sk_production_..."
        config.http_client_settings = { read_timeout: 10, open_timeout: 10 }
      end

      bearer = Bearer.new
      github = bearer.integration("github")
      expect(github).to be_an_instance_of(Bearer::Integration)
      expect(Net::HTTP).to receive(:start).with("some.host.com", 80, {open_timeout: 10, read_timeout: 10, use_ssl: false}) { mock_response }
      github.get("/user/repos")
    end
  end
end
