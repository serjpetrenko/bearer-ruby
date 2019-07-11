# frozen_string_literal: true

class Bearer
  module Errors
    class Configuration < StandardError; end

    class FunctionError < StandardError
      attr_reader :data

      def initialize(data)
        super(data&.to_json)
        @data = data
      end
    end
  end
end
