# frozen_string_literal: true

require_relative "./bearer/configuration"
require_relative "./bearer/integration"

class Bearer
  PRODUCTION_INTEGRATION_HOST = "https://int.bearer.sh"

  # Public: Create an instance of the Bearer client
  #
  # api_key - developer API Key from the Dashboard. Defaults to the value from the `Bearer::Configuration` object
  def initialize(api_key = Bearer::Configuration.api_key, integration_host: nil)
    @api_key = api_key
    @integration_host = integration_host || Bearer::Configuration.integration_host || PRODUCTION_INTEGRATION_HOST
  end

  # Public: Return an integration client
  #
  # integration_id - the integration's unique identifier from the Dashboard
  def integration(integration_id)
    Integration.new(integration_id: integration_id, integration_host: @integration_host, api_key: @api_key)
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
