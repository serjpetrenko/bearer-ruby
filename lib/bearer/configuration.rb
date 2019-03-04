# frozen_string_literal: true

require "singleton"

require_relative "./errors"

module Bearer
  class Configuration
    include Singleton

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
      EXISTING_METHODS = FIELDS.flat_map { |field| [field, "#{field}=".to_sym] }

      def method_missing(name, *args, &block)
        super unless EXISTING_METHODS.include? name
        instance.public_send(name, *args, &block)
      end

      def respond_to_missing?(name, include_private = false)
        EXISTING_METHODS.include?(name) || super
      end
    end

    def self.reset
      FIELDS.each do |field|
        instance.public_send("#{field}=", nil)
      end
    end

    def self.setup
      yield(instance)
    end
  end
end
