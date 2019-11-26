# frozen_string_literal: true

class Bearer
  module Errors
    class Configuration < StandardError; end

    class MissingAuthId < StandardError
      def initialize
        super("No Auth ID has been set. Please call `auth`")
      end
    end
  end
end
