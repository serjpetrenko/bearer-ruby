# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Bearer do
  before do
    stub_request(:post, "https://int.bearer.sh/api/v4/functions/backend/4l1c3/fetch-goats?q=dolly")
      .with(
        body: "{}",
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "api_key",
          "Content-Type" => "application/json",
          "Host" => "int.bearer.sh",
          "User-Agent" => "Bearer (0.2.0)"
        }
      )
      .to_return(status: 200, body: '{"ok":true}', headers: {})
  end
  it "has a version number" do
    expect(Bearer::VERSION).not_to be nil
  end

  describe ".call" do
    let(:uri) { stub_const("URI").as_stubbed_const(transfer_nested_constants: true) }
    it "allows to call bearer backend function" do
      Bearer::Configuration.api_key = "api_key"
      Bearer::Configuration.client_id = "client_id"
      Bearer::Configuration.secret = "secret"
      expect(Bearer.call("4l1c3", "fetch-goats", params: { q: "dolly" })).to eq("ok" => true)
    end
  end

  describe ".invoke" do
    let(:uri) { stub_const("URI").as_stubbed_const(transfer_nested_constants: true) }
    it "allows to call bearer backend function" do
      Bearer::Configuration.api_key = "api_key"
      Bearer::Configuration.client_id = "client_id"
      Bearer::Configuration.secret = "secret"
      expect(Bearer.invoke("4l1c3", "fetch-goats", params: { q: "dolly" })).to eq("ok" => true)
    end
  end
end
