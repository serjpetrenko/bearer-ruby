# frozen_string_literal: true

require "singleton"

require_relative "./errors"

class Bearer
  class Configuration
    include Singleton

    PRODUCTION_INTEGRATION_HOST = "https://int.bearer.sh"

    FIELDS = %i[
      secret_key
      publishable_key
      encryption_key
      integration_host
      http_client_params
    ].freeze

    DEPRECATED_FIELDS = %i[
      api_key
      client_id
      secret
    ].freeze

    DEFAULT_READ_TIMEOUT = 5
    DEFAULT_OPEN_TIMEOUT = 5

    # @return [Hash]
    def integration_host
      @integration_host ||= PRODUCTION_INTEGRATION_HOST
    end

    # @return [Hash]
    def http_client_params
      default_http_client_params.merge(@http_client_params || {})
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

    # @return [String]
    def api_key
      deprecate("api_key", "secret_key")
      secret_key
    end

    # @return [String]
    def client_id
      deprecate("client_id", "publishable_key")
      publishable_key
    end

    # @return [String]
    def secret
      deprecate("secret", "encryption_key")
      encryption_key
    end

    attr_writer(*FIELDS)

    def api_key=(value)
      deprecate("api_key=", "secret_key=")
      @secret_key = value
    end

    def client_id=(value)
      deprecate("client_id=", "publishable_key=")
      @publishable_key = value
    end

    def secret=(value)
      deprecate("secret=", "encryption_key=")
      @encryption_key = value
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
          instance.public_send("#{field}=", nil)
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
    def default_http_client_params
      {
        read_timeout: read_timeout,
        open_timeout: open_timeout
      }
    end
  end
end
