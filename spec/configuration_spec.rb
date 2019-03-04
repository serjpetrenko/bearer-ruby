require_relative "../lib/bearer/configuration"

RSpec.describe Bearer do
  before do
    Bearer::Configuration.reset
  end

  it "is configurable", :aggregate_failures do
    Bearer::Configuration.setup do |config|
      config.api_key = "secret_api_key"
      config.client_id = "client_id"
      config.secret = "secret"
    end
    expect(Bearer::Configuration.api_key).to eq "secret_api_key"
    expect(Bearer::Configuration.client_id).to eq "client_id"
    expect(Bearer::Configuration.secret).to eq "secret"
  end

  it "allows to setup the configuration", :aggregate_failures do
    Bearer::Configuration.api_key = "api_key"
    Bearer::Configuration.client_id = "client_id"
    Bearer::Configuration.secret = "secret"

    expect(Bearer::Configuration.api_key).to eq "api_key"
    expect(Bearer::Configuration.client_id).to eq "client_id"
    expect(Bearer::Configuration.secret).to eq "secret"
  end

  it "raises an error when key is missing", :aggregate_failures do
    expect { Bearer::Configuration.api_key }
      .to raise_error Bearer::Errors::Configuration, "Bearer api_key is missing!"
    expect { Bearer::Configuration.client_id }
      .to raise_error Bearer::Errors::Configuration, "Bearer client_id is missing!"
    expect { Bearer::Configuration.secret }
      .to raise_error Bearer::Errors::Configuration, "Bearer secret is missing!"
  end
end
