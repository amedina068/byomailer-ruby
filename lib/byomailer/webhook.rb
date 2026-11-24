module Byomailer
  # The webhook delivery is not valid. reason is :signature, :timestamp or :payload.
  class WebhookVerificationError < Error
    attr_reader :reason

    def initialize(reason, message)
      @reason = reason
      super(message)
    end
  end

  # Verifies a signed webhook delivery. Use it on the server only, because
  # the endpoint secret is a secret.
  #
  #   event = Byomailer::Webhook.verify(request.raw_post, request.headers)
  #   event.type                   # => "contact.subscribed"
  #   event.payload.contact.email  # => "ana@example.com"
  #   event.delivery_id            # => "5f0c2a8e-..." or nil
  #
  # Give the raw body. A body that you parse and encode again has other bytes,
  # because BYOMailer escapes Unicode as \uXXXX and does not escape "/".
  module Webhook
    EVENT     = "X-Byomailer-Event"
    DELIVERY  = "X-Byomailer-Delivery"
    TIMESTAMP = "X-Byomailer-Timestamp"
    SIGNATURE = "X-Byomailer-Signature"

    # The seconds that a timestamp can be before or after the current time.
    TOLERANCE = 300

    # The events of BYOMailer today. The app can add events, so verify accepts other names too.
    EVENTS = %w[
      contact.subscribed contact.unsubscribed contact.resubscribed
      newsletter.sent sequence_step.sent sequence.completed webhook.test
    ].freeze

    # A verified delivery. payload is the decoded body as a Record. delivery_id
    # is nil when the X-Byomailer-Delivery header is missing, because an older
    # instance does not send it.
    Event = Data.define(:type, :payload, :timestamp, :delivery_id)

    # Returns an Event. Raises WebhookVerificationError with the reason
    # :signature, :timestamp or :payload. The checks run in the same order as
    # in the other SDKs: the signature header, the timestamp header, the
    # signature, the tolerance and the body.
    #
    # headers can be the Rails request.headers, a Rack env or a Hash.
    def self.verify(body, headers, secret: Byomailer.config.webhook_secret, tolerance: TOLERANCE, now: Time.now)
      raise ConfigurationError, "Set the BYOMailer webhook secret to verify a webhook" if secret.to_s.empty?

      signature = header(headers, SIGNATURE)
      timestamp = header(headers, TIMESTAMP).to_s

      raise WebhookVerificationError.new(:signature, "The X-Byomailer-Signature header is missing") if signature.nil?
      raise WebhookVerificationError.new(:timestamp, "The X-Byomailer-Timestamp header is missing or is not a Unix time") unless timestamp.match?(/\A\d+\z/)

      unless OpenSSL.secure_compare(sign(timestamp, body, secret), signature.strip.downcase)
        raise WebhookVerificationError.new(:signature, "The webhook signature does not match the body")
      end

      if (now.to_i - timestamp.to_i).abs > tolerance
        raise WebhookVerificationError.new(:timestamp, "The webhook timestamp is more than #{tolerance} seconds from now")
      end

      payload = parse(body)
      delivery = header(headers, DELIVERY).to_s

      Event.new(type: payload["event"] || header(headers, EVENT).to_s, payload: Record.wrap(payload),
                timestamp: timestamp.to_i, delivery_id: (delivery unless delivery.empty?))
    end

    # The X-Byomailer-Signature value for a timestamp and a raw body.
    def self.sign(timestamp, body, secret)
      "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.".b + body.to_s.b)}"
    end

    # Rails and Hash headers use the header name. A Rack env uses HTTP_X_BYOMAILER_SIGNATURE.
    def self.header(headers, name)
      headers[name] || headers[name.downcase] || headers["HTTP_#{name.upcase.tr("-", "_")}"]
    end

    # The body must be a JSON object.
    def self.parse(body)
      payload = JSON.parse(body)
      payload.is_a?(Hash) ? payload : raise(JSON::ParserError)
    rescue JSON::ParserError
      raise WebhookVerificationError.new(:payload, "The webhook signature is valid, but the body is not a JSON object")
    end
    private_class_method :header, :parse
  end
end
