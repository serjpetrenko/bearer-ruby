# frozen_string_literal: true

require_relative "./errors"

module Bearer
  class Configuration
    FIELDS = %i[api_key client_id secret].freeze

    attr_writer(*FIELDS)

    FIELDS.each do |field|
      define_method field do
        value = instance_variable_get(:"@#{field}")
        raise ::Bearer::Errors::Configuration, "Bearer #{field} is missing!" unless value

        value
      end
    end

    class << self
      def method_missing(name, *args, &block)
        super unless FIELDS.include? name
        configuration.public_send(name)
      end

      def respond_to_missing?(name, include_private = false)
        FIELDS.include?(name) || super
      end
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.reset
      @configuration = Configuration.new
    end

    def self.setup
      yield(configuration)
    end
  end
end
