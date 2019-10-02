require_relative "../lib/bearer/configuration"

RSpec.describe Bearer do
  before do
    Bearer::Configuration.reset
  end

  it "is configurable", :aggregate_failures do
    Bearer::Configuration.setup do |config|
      config.secret_key = "secret_api_key"
      config.publishable_key = "client_id"
      config.encryption_key = "secret"
    end
    expect(Bearer::Configuration.secret_key).to eq "secret_api_key"
    expect(Bearer::Configuration.publishable_key).to eq "client_id"
    expect(Bearer::Configuration.encryption_key).to eq "secret"
  end

  it "allows to setup the configuration", :aggregate_failures do
    Bearer::Configuration.secret_key = "secret_api_key"
    Bearer::Configuration.publishable_key = "client_id"
    Bearer::Configuration.encryption_key = "secret"

    expect(Bearer::Configuration.secret_key).to eq "secret_api_key"
    expect(Bearer::Configuration.publishable_key).to eq "client_id"
    expect(Bearer::Configuration.encryption_key).to eq "secret"
  end

  it "raises an error when key is missing", :aggregate_failures do
    expect { Bearer::Configuration.api_key }
      .to raise_error Bearer::Errors::Configuration, "Bearer secret_key is missing!"
    expect { Bearer::Configuration.client_id }
      .to raise_error Bearer::Errors::Configuration, "Bearer publishable_key is missing!"
    expect { Bearer::Configuration.secret }
      .to raise_error Bearer::Errors::Configuration, "Bearer encryption_key is missing!"

    expect { Bearer::Configuration.secret_key }
      .to raise_error Bearer::Errors::Configuration, "Bearer secret_key is missing!"
    expect { Bearer::Configuration.publishable_key }
      .to raise_error Bearer::Errors::Configuration, "Bearer publishable_key is missing!"
    expect { Bearer::Configuration.encryption_key }
      .to raise_error Bearer::Errors::Configuration, "Bearer encryption_key is missing!"
  end

  it "does NOT raise an error when a missing key is optional" do
    expect { Bearer::Configuration.integration_host }.not_to raise_error
  end
end
