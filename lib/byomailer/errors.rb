module Byomailer
  class Error < StandardError; end

  # A setting that the call needs is missing, for example the instance URL.
  class ConfigurationError < Error; end

  # The request did not get a response: the connection failed or timed out.
  class ConnectionError < Error; end

  # The API returned a status that is not a success.
  class ApiError < Error
    attr_reader :status, :body

    def self.for(response)
      class_for(response.code.to_i).new(response, parse(response.body))
    end

    def self.class_for(status)
      case status
      when 401 then AuthenticationError
      when 403 then AuthorizationError
      when 404 then NotFoundError
      when 422 then ValidationError
      when 429 then RateLimitError
      when 500.. then ServerError
      else ApiError
      end
    end

    def self.parse(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      body
    end
    private_class_method :parse

    def initialize(response, body)
      @status = response.code.to_i
      @body = body
      @retry_after = response["Retry-After"]
      super(body.is_a?(Hash) && body["message"] || "BYOMailer returned HTTP #{status}")
    end

    # The seconds to wait before the next request, from the Retry-After header.
    # A 429 has it. A 503 can have it.
    def retry_after
      return if @retry_after.nil?

      Integer(@retry_after, exception: false) || [ (Time.httpdate(@retry_after) - Time.now).ceil, 0 ].max
    rescue ArgumentError
      nil
    end
  end

  # The token is missing, wrong or revoked.
  class AuthenticationError < ApiError; end

  # A read-only token tried to change data, or a user who is not an admin
  # called a webhook endpoint route.
  class AuthorizationError < ApiError; end

  class NotFoundError < ApiError; end
  class ServerError < ApiError; end

  class ValidationError < ApiError
    # The field errors, for example { "email" => ["The email field is required."] }.
    def errors
      body.is_a?(Hash) && body["errors"] || {}
    end
  end

  class RateLimitError < ApiError; end
end
