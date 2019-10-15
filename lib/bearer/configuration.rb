# frozen_string_literal: true

require "singleton"

require_relative "./errors"

class Bearer
  # stores global Bearer configuration options
  # @see https://app.bearer.sh/settings
  # @attr_writer [String] secret_key secret key from https://app.bearer.sh/settings
  # @attr_writer [String] publishable_key publishable key from https://app.bearer.sh/settings
  # @attr_writer [String] encryption_key encryption key from https://app.bearer.sh/settings
  # @attr_writer [Hash] http_client_settings options passed as a parameters to Net::HTTP#start
  # @attr_writer [String] host mainly used internally
  class Configuration
    include Singleton

    PRODUCTION_INTEGRATION_HOST = "https://proxy.bearer.sh"

    FIELDS = %i[
      secret_key
      publishable_key
      encryption_key
      host
      http_client_settings
      log_level
    ].freeze

    DEPRECATED_FIELDS = %i[
      api_key
      client_id
      secret
      integration_host
      http_client_params
    ].freeze

    DEFAULT_READ_TIMEOUT = 5
    DEFAULT_OPEN_TIMEOUT = 5

    # @return [String]
    def integration_host
      deprecate("integration_host", "host")
      host
    end

    # @return [Integer]
    def log_level
      @log_level ||= :info
    end

    # @return [String]
    def host
      @host ||= PRODUCTION_INTEGRATION_HOST
    end

    # @return [Hash]
    def http_client_settings
      default_http_client_settings.merge(@http_client_settings || {})
    end

    # @deprecated use {#http_client_settings} instead
    # @return [Hash<String,String>]
    def http_client_params
      deprecate("http_client_params", "http_client_settings")
      http_client_settings
    end

    # @return [String]
    def secret_key
      raise_if_missing(:secret_key)
    end

    # @return [String]
    def publishable_key
      raise_if_missing(:publishable_key)
    end

    # @return [String]
    def encryption_key
      raise_if_missing(:encryption_key)
    end

    # @deprecated Use {#secret_key} instead.
    # @return [String]
    def api_key
      deprecate("api_key", "secret_key")
      secret_key
    end

    # @deprecated Use {#publishable_key} instead.
    # @return [String]
    def client_id
      deprecate("client_id", "publishable_key")
      publishable_key
    end

    # @deprecated Use {#encryption_key} instead.
    # @return [String]
    def secret
      deprecate("secret", "encryption_key")
      encryption_key
    end

    attr_writer(*FIELDS)

    # @deprecated Use {#secret_key=} instead.
    # @return [void]
    def api_key=(value)
      deprecate("api_key=", "secret_key=")
      @secret_key = value
    end

    # @deprecated Use {#publishable_key=} instead.
    # @return [void]
    def client_id=(value)
      deprecate("client_id=", "publishable_key=")
      @publishable_key = value
    end

    # @deprecated Use {#encryption_key=} instead.
    # @return [void]
    def secret=(value)
      deprecate("secret=", "encryption_key=")
      @encryption_key = value
    end

    # @deprecated Use {#host=} instead.
    # @return [void]
    def integration_host=(value)
      deprecate("integration_host=", "host=")
      @host = value
    end

    # @deprecated Use {#http_client_settings=} instead.
    # @return [void]
    def http_client_params=(value)
      deprecate("http_client_params=", "http_client_settings=")
      @http_client_settings = value
    end

    def log_level=(severity)
      Bearer.logger.level = severity
      @log_level = severity
    end

    class << self
      ALL_METHODS = [*FIELDS, *DEPRECATED_FIELDS].freeze
      EXISTING_METHODS = ALL_METHODS.flat_map { |field| [field, "#{field}=".to_sym] }

      def method_missing(name, *args, &block)
        super unless EXISTING_METHODS.include? name
        instance.public_send(name, *args, &block)
      end

      def respond_to_missing?(name, include_private = false)
        EXISTING_METHODS.include?(name) || super
      end

      def reset
        FIELDS.each do |field|
          value = field == :log_level ? :info : nil
          instance.public_send("#{field}=", value)
        end
      end

      def setup
        yield(instance)
      end
    end

    private


    def raise_if_missing(field)
      value = instance_variable_get(:"@#{field}")

      raise ::Bearer::Errors::Configuration, "Bearer #{field} is missing!" unless value

      value
    end

    def deprecate(old_field, new_field)
      puts "Bearer Deprecation Warning: #{old_field} is deprecated, use #{new_field} instead"
    end

    # defaults to 5 seconds
    # @return [Integer]
    def open_timeout
      @open_timeout || DEFAULT_READ_TIMEOUT
    end

    # defaults to 5 seconds
    # @return [Integer]
    def read_timeout
      @read_timeout || DEFAULT_READ_TIMEOUT
    end

    # @return [Hash]
    def default_http_client_settings
      {
        read_timeout: read_timeout,
        open_timeout: open_timeout
      }
    end
  end
end
