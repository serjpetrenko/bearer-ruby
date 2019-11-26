# frozen_string_literal: true

RSpec.describe Bearer::AuthDetails do
  subject(:auth_details) { described_class.new(raw_data) }

  let(:callback_params) { { callback: "param" } }
  let(:response_headers) { { "content-type": "application/json" } }
  let(:response_body) { { response: "body" } }
  let(:token_response) { { headers: response_headers, body: response_body } }

  context "OAuth 1" do
    let(:consumer_key) { "test-consumer-key" }
    let(:consumer_secret) { "test-secret" }
    let(:token_secret) { "test-token-secret" }
    let(:raw_access_token) { { value: "test-token", iat: 1574087265 } }

    let(:raw_data) do
      {
        accessToken: raw_access_token,
        callbackParams: callback_params,
        consumerKey: consumer_key,
        consumerSecret: consumer_secret,
        signatureMethod: "HMAC-SHA1",
        tokenResponse: token_response,
        tokenSecret: token_secret
      }
    end

    describe "#callback_params" do
      subject { auth_details.callback_params }
      it { is_expected.to eq(callback_params) }
    end

    describe "#consumer_key" do
      subject { auth_details.consumer_key }
      it { is_expected.to eq(consumer_key) }
    end

    describe "#consumer_secret" do
      subject { auth_details.consumer_secret }
      it { is_expected.to eq(consumer_secret) }
    end

    describe "#signature_method" do
      subject { auth_details.signature_method }
      it { is_expected.to eq(Bearer::AuthDetails::OAuth1SignatureMethod::HMAC_SHA1) }
    end

    describe "#token_response" do
      describe "#body" do
        subject { auth_details.token_response.body }
        it { is_expected.to eq(response_body) }
      end

      describe "#headers" do
        subject { auth_details.token_response.headers }
        it { is_expected.to eq(response_headers) }
      end
    end

    describe "#token_secret" do
      subject { auth_details.token_secret }
      it { is_expected.to eq(token_secret) }
    end

    describe "#access_token" do
      let(:token_data) { instance_double(Bearer::AuthDetails::TokenData) }

      it "returns the decoded token data" do
        expect(Bearer::AuthDetails::TokenData).to receive(:new).with(raw_access_token).and_return(token_data)

        expect(auth_details.access_token).to eq(token_data)
      end
    end
  end

  context "OAuth 2" do
    let(:client_id) { "test-client-id" }
    let(:client_secret) { "test-secret" }
    let(:raw_access_token) { { value: "test-access", iat: 1574087265 } }
    let(:raw_refresh_token) { { value: "test-refresh", iat: 1574087265 } }
    let(:raw_id_token) { { value: "test-id", iat: 1574087265 } }
    let(:id_token_jwt) { { jwt: "data" } }

    let(:raw_data) do
      {
        accessToken: raw_access_token,
        callbackParams: callback_params,
        clientID: client_id,
        clientSecret: client_secret,
        idToken: raw_id_token,
        idTokenJwt: id_token_jwt,
        tokenResponse: token_response,
        refreshToken: raw_refresh_token
      }
    end

    before do
      allow(Bearer::AuthDetails::TokenData).to receive(:new)
    end

    describe "#callback_params" do
      subject { auth_details.callback_params }
      it { is_expected.to eq(callback_params) }
    end

    describe "#client_id" do
      subject { auth_details.client_id }
      it { is_expected.to eq(client_id) }
    end

    describe "#client_secret" do
      subject { auth_details.client_secret }
      it { is_expected.to eq(client_secret) }
    end

    describe "#id_token_jwt" do
      subject { auth_details.id_token_jwt }
      it { is_expected.to eq(id_token_jwt) }
    end

    describe "#token_response" do
      describe "#body" do
        subject { auth_details.token_response.body }
        it { is_expected.to eq(response_body) }
      end

      describe "#headers" do
        subject { auth_details.token_response.headers }
        it { is_expected.to eq(response_headers) }
      end
    end

    describe "#access_token" do
      let(:token_data) { instance_double(Bearer::AuthDetails::TokenData) }

      it "returns the decoded token data" do
        expect(Bearer::AuthDetails::TokenData).to receive(:new).with(raw_access_token).and_return(token_data)

        expect(auth_details.access_token).to eq(token_data)
      end
    end

    describe "#id_token" do
      subject { auth_details.id_token }

      let(:token_data) { instance_double(Bearer::AuthDetails::TokenData) }

      it "returns the decoded token data" do
        expect(Bearer::AuthDetails::TokenData).to receive(:new).with(raw_id_token).and_return(token_data)

        expect(auth_details.id_token).to eq(token_data)
      end

      context "when there is no id token" do
        let(:raw_id_token) { nil }
        it { is_expected.to be_nil }
      end
    end

    describe "#refresh_token" do
      subject { auth_details.refresh_token }

      let(:token_data) { instance_double(Bearer::AuthDetails::TokenData) }

      it "returns the decoded token data" do
        expect(Bearer::AuthDetails::TokenData).to receive(:new).with(raw_refresh_token).and_return(token_data)

        expect(auth_details.refresh_token).to eq(token_data)
      end

      context "when there is no refresh token" do
        let(:raw_refresh_token) { nil }
        it { is_expected.to be_nil }
      end
    end
  end

  describe Bearer::AuthDetails::TokenData do
    subject(:token_data) { described_class.new(raw_data) }

    let(:client_id) { "test-client-id" }
    let(:exp) { 1573665039 }
    let(:scope) { "read write" }
    let(:token_type) { "bearer" }
    let(:value) { "test-token" }

    let(:raw_data) do
      {
        active: true,
        client_id: client_id,
        exp: exp,
        iat: 1573661439,
        scope: scope,
        token_type: token_type,
        value: value
      }
    end

    describe "#active?" do
      subject { auth_details.active? }
      it { is_expected.to be_truthy }
    end

    describe "#client_id" do
      subject { auth_details.client_id }
      it { is_expected.to eq(client_id) }
    end

    describe "#expires_at" do
      subject { auth_details.expires_at }

      it { is_expected.to eq(Time.utc(2019, 11, 13, 17, 10, 39)) }

      context "when there is no exp value" do
        let(:exp) { nil }
        it { is_expected.to be_nil }
      end
    end

    describe "#issued_at" do
      subject { auth_details.issued_at }
      it { is_expected.to eq(Time.utc(2019, 11, 13, 16, 10, 39)) }
    end

    describe "#scopes" do
      subject { auth_details.scopes }

      it { is_expected.to eq(["read", "write"]) }

      context "when there is no scope and the token type supports scopes" do
        let(:token_type) { "bearer" }
        let(:scope) { nil }
        it { is_expected.to eq([]) }
      end

      context "when there is no scope and the token type does NOT support scopes" do
        let(:token_type) { "id" }
        let(:scope) { nil }
        it { is_expected.to be_nil }
      end
    end

    describe "#token_type" do
      subject { auth_details.token_type }
      it { is_expected.to eq(Bearer::AuthDetails::TokenType::OAUTH2_ACCESS_TOKEN) }
    end

    describe "#value" do
      subject { auth_details.value }
      it { is_expected.to eq(value) }
    end
  end
end
