require "test_helper"

class Byomailer::WebhookEndpointsTest < Byomailer::TestCase
  ENDPOINT = { id: 5, url: "https://example.com/webhooks", events: [ "contact.subscribed" ], active: true }.freeze

  def test_list
    stub_api(:get, "/webhook-endpoints").to_return(cursor_page([ ENDPOINT ]))

    assert_equal [ "https://example.com/webhooks" ], client.webhook_endpoints.list.map(&:url)
  end

  def test_find_has_no_secret
    stub_api(:get, "/webhook-endpoints/5").to_return(json(data: ENDPOINT))

    endpoint = client.webhook_endpoints.find(5)

    refute endpoint.key?(:secret)
  end

  def test_create_returns_the_secret
    stub_api(:post, "/webhook-endpoints").with(body: { url: "https://example.com/webhooks", events: [ "contact.subscribed" ] })
      .to_return(json({ data: ENDPOINT.merge(secret: "whsec_example") }, status: 201))

    endpoint = client.webhook_endpoints.create(url: "https://example.com/webhooks", events: [ "contact.subscribed" ])

    assert_equal "whsec_example", endpoint.secret
  end

  def test_update
    stub_api(:patch, "/webhook-endpoints/5").with(body: { active: false }).to_return(json(data: ENDPOINT.merge(active: false)))

    refute client.webhook_endpoints.update(5, active: false).active
  end

  def test_delete
    stub = stub_api(:delete, "/webhook-endpoints/5").to_return(no_content)

    client.webhook_endpoints.delete(5)

    assert_requested stub
  end

  def test_deliveries
    stub_api(:get, "/webhook-endpoints/5/deliveries", query: { per_page: "10" })
      .to_return(cursor_page([ { id: 1, event_type: "contact.subscribed", status: "success" } ]))

    assert_equal [ "success" ], client.webhook_endpoints.deliveries(5, per_page: 10).map(&:status)
  end

  def test_rotate_secret
    stub_api(:post, "/webhook-endpoints/5/secret").to_return(json(data: ENDPOINT.merge(secret: "whsec_new")))

    assert_equal "whsec_new", client.webhook_endpoints.rotate_secret(5).secret
  end

  def test_send_test
    stub_api(:post, "/webhook-endpoints/5/test").to_return(json({ data: { id: 2, event_type: "webhook.test", status: "pending" } }, status: 202))

    assert_equal "webhook.test", client.webhook_endpoints.send_test(5).event_type
  end

  def test_a_user_who_is_not_an_admin_gets_an_authorization_error
    stub_api(:get, "/webhook-endpoints").to_return(json({ message: "" }, status: 403))

    assert_raises(Byomailer::AuthorizationError) { client.webhook_endpoints.list }
  end
end
