# frozen_string_literal: true

require_relative "./bearer/version"
require_relative "./bearer/configuration"
require "net/http"
require "json"

module Bearer
  INT_URL = "https://int.bearer.sh/api/v3/functions/backend/"

  def self.call(integration_uuid, integration_name, params: {}, body: {})
    uri = URI("#{INT_URL}#{integration_uuid}/#{integration_name}")
    uri.query = params.map { |k, v| "#{k}=#{v}" }.join("&")

    req = Net::HTTP::Post.new(
      uri,
      "Content-Type" => "application/json",
      "Authorization" => Bearer::Configuration.api_key,
      "User-Agent" => "Bearer (#{Bearer::VERSION})"
    )
    req.body = body.to_json
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end
    JSON.parse(res.body)
  end
end
