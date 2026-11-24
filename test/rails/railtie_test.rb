require "rails_helper"

class Byomailer::RailtieTest < ActiveSupport::TestCase
  test "reads the settings from the credentials" do
    assert_equal "https://mail.example.com", Byomailer.config.url
    assert_equal "credentials-token", Byomailer.config.token
    assert_equal "whsec_credentials", Byomailer.config.webhook_secret
  end

  test "an initializer runs after the credentials and wins" do
    assert_equal 5, Byomailer.config.timeout
    assert_equal 5, Byomailer.client.timeout
  end

  test "the default client uses the credentials" do
    assert_equal "https://mail.example.com", Byomailer.client.url
  end
end

class Byomailer::WebhookControllerTest < ActionDispatch::IntegrationTest
  test "a controller verifies a delivery with request.raw_post and request.headers" do
    body = %({"event":"contact.subscribed","occurred_at":"2026-11-18T10:00:00+00:00","contact":{"email":"ana@example.com"}})

    post "/webhooks/byomailer", params: body, headers: signed_headers(body)

    assert_response :success
    assert_equal "contact.subscribed", response.body
  end

  test "a controller reads the delivery ID from request.headers" do
    body = %({"event":"contact.subscribed","occurred_at":"2026-11-18T10:00:00+00:00"})

    post "/webhooks/byomailer", params: body, headers: signed_headers(body).merge("X-Byomailer-Delivery" => "5f0c2a8e")

    assert_response :success
    assert_equal "contact.subscribed 5f0c2a8e", response.body
  end

  test "a controller rejects a body that changed after signing" do
    body = %({"event":"contact.subscribed"})

    post "/webhooks/byomailer", params: body.sub("subscribed", "unsubscribed"), headers: signed_headers(body)

    assert_response :bad_request
    assert_equal "signature", response.body
  end

  private
    def signed_headers(body, timestamp: Time.now.to_i.to_s)
      {
        "Content-Type" => "application/json",
        "X-Byomailer-Event" => "contact.subscribed",
        "X-Byomailer-Timestamp" => timestamp,
        "X-Byomailer-Signature" => Byomailer::Webhook.sign(timestamp, body, "whsec_credentials")
      }
    end
end
