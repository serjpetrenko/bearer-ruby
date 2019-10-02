# frozen_string_literal: true

require_relative "./bearer/configuration"
require_relative "./bearer/integration"

class Bearer
  # Public: Create an instance of the Bearer client
  #
  # api_key - developer API Key from the Dashboard. Defaults to the value from the `Bearer::Configuration` object
  def initialize(secret_key = Bearer::Configuration.secret_key, integration_host: nil)
    @secret_key = secret_key
    @integration_host = integration_host || Bearer::Configuration.integration_host
  end

  # Public: Return an integration client
  #
  # integration_id - the integration's unique identifier from the Dashboard
  def integration(integration_id)
    Integration.new(integration_id: integration_id, integration_host: @integration_host, secret_key: @secret_key)
  end

  class << self
    def call(integration_buid, integration_name, params: {}, body: {})
      integration(integration_buid).invoke(integration_name, body: body, query: params)
    end

    alias invoke call

    def integration(integration_id)
      new.integration(integration_id)
    end
  end
end
