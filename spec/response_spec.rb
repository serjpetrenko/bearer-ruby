# frozen_string_literal: true
require "spec_helper"

RSpec.describe Bearer::Response do
  describe ".from_net_http" do
    subject(:from_net_http) { described_class.from_net_http(http_resp)}

    let(:http_resp) do
      double(body: "{}", code: "200", :[] => "whatever", to_hash: {})
    end

    it "parses json body when it can" do
      expect(from_net_http.data).to eq({})
    end

    context "when http response body is not JSON parsable" do

      let(:http_resp) do
        double(body: "", code: "200", :[] => "whatever", to_hash: {})
      end
      it "sets #data to `response body is not JSON parsable`"  do
        expect(from_net_http.data).to eq("response body is not JSON parsable")

      end
    end
  end
end
