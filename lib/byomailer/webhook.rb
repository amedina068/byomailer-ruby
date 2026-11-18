module Byomailer
  # The webhook delivery is not valid. reason is :signature or :timestamp.
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
  #   event.event   # => "contact.subscribed"
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

    # Returns the decoded payload as a Record. Raises WebhookVerificationError
    # when the signature does not match or the timestamp is too old or too new.
    #
    # headers can be the Rails request.headers, a Rack env or a Hash.
    def self.verify(body, headers, secret: Byomailer.config.webhook_secret, tolerance: TOLERANCE, now: Time.now)
      raise ConfigurationError, "Set the BYOMailer webhook secret to verify a webhook" if secret.to_s.empty?

      timestamp = header(headers, TIMESTAMP).to_s
      signature = header(headers, SIGNATURE).to_s

      unless OpenSSL.secure_compare(sign(timestamp, body, secret), signature)
        raise WebhookVerificationError.new(:signature, "The webhook signature does not match the body")
      end

      unless timestamp.match?(/\A\d+\z/) && (now.to_i - timestamp.to_i).abs <= tolerance
        raise WebhookVerificationError.new(:timestamp, "The webhook timestamp is more than #{tolerance} seconds from now")
      end

      Record.wrap(JSON.parse(body))
    end

    # The X-Byomailer-Signature value for a timestamp and a raw body.
    def self.sign(timestamp, body, secret)
      "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.".b + body.to_s.b)}"
    end

    # Rails and Hash headers use the header name. A Rack env uses HTTP_X_BYOMAILER_SIGNATURE.
    def self.header(headers, name)
      headers[name] || headers[name.downcase] || headers["HTTP_#{name.upcase.tr("-", "_")}"]
    end
    private_class_method :header
  end
end
