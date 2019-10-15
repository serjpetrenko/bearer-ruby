# frozen_string_literal: true

require_relative "./bearer/configuration"
require_relative "./bearer/integration"
require "logger"

# Ruby bindings for Bearer
class Bearer
  # Create an instance of the Bearer client
  # @param secret_key [String] developer secret Key from https://app.bearer.sh/settings.
  # @param host [String] used internally
  def initialize(secret_key = Bearer::Configuration.secret_key, host: Bearer::Configuration.host)
    @secret_key = secret_key
    @host = host
  end

  # Return an integration client
  #
  # @param http_client_settings [Hash<String,String>] sent as keyword arguments to Net::HTTP.start method
  # @param integration_id [String] bearer api id
  # @return [Bearer::Integration]
  def integration(integration_id, http_client_settings: {})
    Integration.new(
      integration_id: integration_id,
      host: @host,
      secret_key: @secret_key,
      http_client_settings: http_client_settings
    )
  end

  # @see {Bearer#integration}
  # @param (see #integration)
  # @return [Bearer::Integration]
  def self.integration(integration_id, http_client_settings: {})
    new.integration(integration_id, http_client_settings: http_client_settings)
  end

  # @see {Logger}
  # @return [Logger]
  def self.logger
    @logger ||= Logger.new(STDOUT, level: Bearer::Configuration.log_level)
  end
end
