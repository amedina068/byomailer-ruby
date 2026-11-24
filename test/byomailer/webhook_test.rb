require "test_helper"

class Byomailer::WebhookTest < Byomailer::TestCase
  VECTORS = JSON.parse(File.read(File.expand_path("../fixtures/webhook-signature-vectors.json", __dir__)))
  SECRET = "whsec_test0123456789abcdefghijklmnopqrstuvwxyz"

  VECTORS["cases"].each do |vector|
    define_method("test_vector_#{vector["name"].gsub(/\W+/, "_")}") do
      headers = {
        "X-Byomailer-Timestamp" => vector["timestamp"],
        "X-Byomailer-Signature" => vector["signature"],
        "X-Byomailer-Delivery" => vector["delivery"]
      }.compact
      verify = -> { Byomailer::Webhook.verify(vector["body"], headers, secret: vector["secret"], now: vector["now"]) }

      if vector["valid"]
        event = verify.call
        payload = JSON.parse(vector["body"])

        assert_equal payload["event"], event.type
        assert_equal payload, event.payload.to_h
        assert_equal vector["timestamp"].to_i, event.timestamp
        if vector["delivery_id"]
          assert_equal vector["delivery_id"], event.delivery_id
        else
          assert_nil event.delivery_id
        end
      else
        error = assert_raises(Byomailer::WebhookVerificationError) { verify.call }
        assert_equal vector["reason"].to_sym, error.reason
      end
    end
  end

  def test_the_vectors_use_a_tolerance_of_300_seconds
    assert_equal VECTORS["tolerance_seconds"], Byomailer::Webhook::TOLERANCE
  end

  def test_returns_an_event_with_the_payload_as_a_record
    event = verify(delivery("contact.subscribed", contact: { email: "ana@example.com" }))

    assert_equal "contact.subscribed", event.type
    assert_equal "ana@example.com", event.payload.contact.email
    assert_nil event.delivery_id
  end

  def test_reads_the_delivery_id
    body, headers = delivery("webhook.test")

    assert_equal "5f0c2a8e", verify([ body, headers.merge("X-Byomailer-Delivery" => "5f0c2a8e") ]).delivery_id
    assert_nil verify([ body, headers.merge("X-Byomailer-Delivery" => "") ]).delivery_id
  end

  def test_the_type_comes_from_the_event_header_when_the_payload_has_no_event
    body = %({"occurred_at":"2025-11-18T10:00:00+00:00"})
    timestamp = Time.now.to_i
    headers = { "X-Byomailer-Event" => "contact.bounced", "X-Byomailer-Timestamp" => timestamp.to_s, "X-Byomailer-Signature" => Byomailer::Webhook.sign(timestamp, body, SECRET) }

    assert_equal "contact.bounced", verify([ body, headers ]).type
  end

  def test_accepts_an_unknown_event
    assert_equal "contact.bounced", verify(delivery("contact.bounced")).type
  end

  def test_the_tolerance_can_change
    body, headers = delivery("webhook.test", timestamp: 1_000)

    assert verify([ body, headers ], tolerance: 600, now: 1_500)

    error = assert_raises(Byomailer::WebhookVerificationError) { verify([ body, headers ], tolerance: 60, now: 1_500) }
    assert_equal :timestamp, error.reason
  end

  def test_now_can_be_a_time
    body, headers = delivery("webhook.test", timestamp: 1_000)

    assert verify([ body, headers ], now: Time.at(1_100))
  end

  def test_reads_rack_env_headers
    body, headers = delivery("webhook.test")
    env = { "HTTP_X_BYOMAILER_TIMESTAMP" => headers["X-Byomailer-Timestamp"], "HTTP_X_BYOMAILER_SIGNATURE" => headers["X-Byomailer-Signature"] }

    assert Byomailer::Webhook.verify(body, env, secret: SECRET)
  end

  def test_reads_lowercase_headers
    body, headers = delivery("webhook.test")

    assert Byomailer::Webhook.verify(body, headers.transform_keys(&:downcase), secret: SECRET)
  end

  def test_missing_headers_fail_on_the_signature
    error = assert_raises(Byomailer::WebhookVerificationError) { Byomailer::Webhook.verify("{}", {}, secret: SECRET) }

    assert_equal :signature, error.reason
  end

  def test_a_missing_timestamp_fails_on_the_timestamp
    headers = { "X-Byomailer-Signature" => "sha256=#{"0" * 64}" }
    error = assert_raises(Byomailer::WebhookVerificationError) { Byomailer::Webhook.verify("{}", headers, secret: SECRET) }

    assert_equal :timestamp, error.reason
  end

  def test_a_timestamp_that_is_not_a_number_fails_on_the_timestamp
    body = %({"event":"webhook.test"})
    headers = { "X-Byomailer-Timestamp" => "soon", "X-Byomailer-Signature" => Byomailer::Webhook.sign("soon", body, SECRET) }

    error = assert_raises(Byomailer::WebhookVerificationError) { Byomailer::Webhook.verify(body, headers, secret: SECRET) }
    assert_equal :timestamp, error.reason
  end

  def test_a_binary_body_with_utf8_bytes
    body = %({"event":"webhook.test","name":"Café"}).b
    headers = { "X-Byomailer-Timestamp" => Time.now.to_i.to_s }
    headers["X-Byomailer-Signature"] = Byomailer::Webhook.sign(headers["X-Byomailer-Timestamp"], body, SECRET)

    assert_equal "Café", Byomailer::Webhook.verify(body, headers, secret: SECRET).payload.name
  end

  def test_the_secret_defaults_to_the_configuration
    Byomailer.config.webhook_secret = SECRET

    assert Byomailer::Webhook.verify(*delivery("webhook.test"))
  ensure
    Byomailer.instance_variable_set(:@config, nil)
  end

  def test_a_missing_secret_is_a_configuration_error
    assert_raises(Byomailer::ConfigurationError) { Byomailer::Webhook.verify(*delivery("webhook.test"), secret: nil) }
  end

  private
    def delivery(event, timestamp: Time.now.to_i, **fields)
      body = JSON.generate(event:, occurred_at: "2025-11-18T10:00:00+00:00", **fields)
      [ body, { "X-Byomailer-Timestamp" => timestamp.to_s, "X-Byomailer-Signature" => Byomailer::Webhook.sign(timestamp, body, SECRET) } ]
    end

    def verify((body, headers), secret: SECRET, **options)
      Byomailer::Webhook.verify(body, headers, secret:, **options)
    end
end
