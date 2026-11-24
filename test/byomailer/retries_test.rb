require "test_helper"

class Byomailer::RetriesTest < Byomailer::TestCase
  def test_retries_a_get_after_a_server_error
    stub = stub_api(:get, "/contacts/1").to_return(json({}, status: 503)).then.to_return(json(data: { id: 1 }))
    client = client()

    assert_equal 1, client.contacts.find(1).id
    assert_requested stub, times: 2
    assert_equal 1, client.pauses.size
  end

  def test_stops_after_max_retries
    stub = stub_api(:get, "/contacts/1").to_return(json({}, status: 500))

    assert_raises(Byomailer::ServerError) { client(max_retries: 2).contacts.find(1) }
    assert_requested stub, times: 3
  end

  def test_backoff_grows_and_has_jitter
    stub_api(:get, "/contacts/1").to_return(json({}, status: 500))
    client = client(max_retries: 5)

    assert_raises(Byomailer::ServerError) { client.contacts.find(1) }

    client.pauses.zip([ 0.5, 1, 2, 4, 8 ]).each do |pause, backoff|
      assert_operator pause, :>=, backoff / 2.0
      assert_operator pause, :<=, backoff
    end
  end

  def test_never_retries_a_post_after_a_server_error
    stub = stub_api(:post, "/lists").to_return(json({ message: "Server Error" }, status: 500))

    assert_raises(Byomailer::ServerError) { client.lists.create(name: "Customers") }
    assert_requested stub, times: 1
  end

  IDEMPOTENT_WRITES = {
    "contacts.update" => [ :patch, "/contacts/42", ->(client) { client.contacts.update(42, name: "Ana") } ],
    "contacts.unsubscribe" => [ :post, "/contacts/42/unsubscribe", ->(client) { client.contacts.unsubscribe(42) } ],
    "contacts.subscribe" => [ :post, "/contacts/42/subscribe", ->(client) { client.contacts.subscribe(42) } ],
    "newsletters.count_recipients" => [ :post, "/newsletters/contacts/preview", ->(client) { client.newsletters.count_recipients } ],
    "tags.rename" => [ :patch, "/tags/5", ->(client) { client.tags.rename(5, name: "gold") } ],
    "lists.rename" => [ :patch, "/lists/3", ->(client) { client.lists.rename(3, name: "Buyers") } ],
    "topics.update" => [ :patch, "/lists/3/topics/8", ->(client) { client.topics.update(3, 8, name: "Offers") } ],
    "blocks.update" => [ :patch, "/blocks/2", ->(client) { client.blocks.update(2, name: "footer", html_content: "<p>Bye</p>") } ],
    "projects.rename" => [ :patch, "/projects/4", ->(client) { client.projects.rename(4, name: "Shop") } ],
    "newsletters.replace_variables" => [ :patch, "/newsletters/7/variables", ->(client) { client.newsletters.replace_variables(7, {}) } ],
    "sequences.replace_variables" => [ :patch, "/sequences/3/variables", ->(client) { client.sequences.replace_variables(3, {}) } ],
    "sequences.replace_step_filters" => [ :patch, "/sequences/3/steps/11/filters", ->(client) { client.sequences.replace_step_filters(3, 11, []) } ],
    "webhook_endpoints.update" => [ :patch, "/webhook-endpoints/12", ->(client) { client.webhook_endpoints.update(12, active: true) } ]
  }

  IDEMPOTENT_WRITES.each do |name, (method, path, call)|
    define_method("test_retries_#{name.tr(".", "_")}_after_a_server_error") do
      stub = stub_api(method, path).to_return(json({}, status: 502)).then.to_return(json(data: { id: 1 }, count: 1))

      call.call(client)

      assert_requested stub, times: 2
    end
  end

  NOT_IDEMPOTENT_WRITES = {
    "contacts.add" => [ :post, "/lists/3/contacts", ->(client) { client.contacts.add(3, "ana@example.com") } ],
    "newsletters.update" => [ :patch, "/newsletters/7", ->(client) { client.newsletters.update(7, title: "News") } ],
    "newsletters.pick_winner" => [ :post, "/newsletters/7/ab-winner", ->(client) { client.newsletters.pick_winner(7, "a") } ],
    "webhook_endpoints.rotate_secret" => [ :post, "/webhook-endpoints/12/secret", ->(client) { client.webhook_endpoints.rotate_secret(12) } ]
  }

  NOT_IDEMPOTENT_WRITES.each do |name, (method, path, call)|
    define_method("test_never_retries_#{name.tr(".", "_")}_after_a_server_error") do
      stub = stub_api(method, path).to_return(json({}, status: 502))

      assert_raises(Byomailer::ServerError) { call.call(client) }
      assert_requested stub, times: 1
    end
  end

  def test_a_server_error_with_retry_after_waits_for_that_time
    stub_api(:get, "/tags").to_return(json({}, status: 503, headers: { "Retry-After" => "4" })).then.to_return(json(data: []))
    client = client()

    client.tags.list

    assert_equal [ 4 ], client.pauses
  end

  def test_retries_a_delete_after_a_server_error
    stub = stub_api(:delete, "/lists/3").to_return(json({}, status: 502)).then.to_return(no_content)

    client.lists.delete(3)

    assert_requested stub, times: 2
  end

  def test_retries_count_recipients_after_a_server_error
    stub = stub_api(:post, "/newsletters/contacts/preview").to_return(json({}, status: 500)).then.to_return(json(count: 12))

    assert_equal 12, client.newsletters.count_recipients
    assert_requested stub, times: 2
  end

  def test_retries_a_post_after_a_rate_limit_and_waits_for_retry_after
    stub = stub_api(:post, "/newsletters/7/test-mail")
      .to_return(json({ message: "Too Many Attempts." }, status: 429, headers: { "Retry-After" => "7" }))
      .then.to_return(json(message: "Test email sent to dev@example.com", sent_to: "dev@example.com"))
    client = client()

    assert_equal "dev@example.com", client.newsletters.send_test(7).sent_to
    assert_requested stub, times: 2
    assert_equal [ 7 ], client.pauses
  end

  def test_a_rate_limit_without_retry_after_uses_the_backoff
    stub_api(:get, "/tags").to_return(json({}, status: 429)).then.to_return(json(data: []))
    client = client()

    client.tags.list

    assert_operator client.pauses.first, :<=, 0.5
  end

  def test_does_not_wait_for_a_long_retry_after
    stub = stub_api(:post, "/webhook-endpoints/5/test").to_return(json({}, status: 429, headers: { "Retry-After" => "3600" }))

    error = assert_raises(Byomailer::RateLimitError) { client.webhook_endpoints.send_test(5) }

    assert_equal 3600, error.retry_after
    assert_requested stub, times: 1
  end

  { dns: SocketError, refused: Errno::ECONNREFUSED, connect_timeout: Net::OpenTimeout }.each do |name, error|
    define_method("test_retries_a_post_after_a_connection_error_before_the_send_#{name}") do
      stub = stub_api(:post, "/lists").to_raise(error).then.to_return(json({ data: { id: 3 } }, status: 201))

      assert_equal 3, client.lists.create(name: "Customers").id
      assert_requested stub, times: 2
    end
  end

  def test_never_retries_a_post_after_a_reset_after_the_send
    stub = stub_api(:post, "/lists").to_raise(Errno::ECONNRESET)

    assert_raises(Byomailer::ConnectionError) { client.lists.create(name: "Customers") }
    assert_requested stub, times: 1
  end

  def test_retries_an_idempotent_post_after_a_timeout
    stub = stub_api(:post, "/contacts/42/unsubscribe").to_raise(Net::ReadTimeout).then.to_return(json(data: { id: 42 }))

    assert_equal 42, client.contacts.unsubscribe(42).id
    assert_requested stub, times: 2
  end

  def test_never_retries_a_post_after_the_server_possibly_received_it
    stub = stub_api(:post, "/lists").to_raise(Net::ReadTimeout)

    assert_raises(Byomailer::ConnectionError) { client.lists.create(name: "Customers") }
    assert_requested stub, times: 1
  end

  def test_retries_a_get_after_a_read_timeout
    stub = stub_api(:get, "/tags").to_raise(Net::ReadTimeout).then.to_return(json(data: []))

    client.tags.list

    assert_requested stub, times: 2
  end

  def test_never_retries_a_client_error
    stub = stub_api(:get, "/contacts/9").to_return(json({ message: "Not found." }, status: 404))

    assert_raises(Byomailer::NotFoundError) { client.contacts.find(9) }
    assert_requested stub, times: 1
  end

  def test_max_retries_zero_turns_retries_off
    stub = stub_api(:get, "/tags").to_return(json({}, status: 503))

    assert_raises(Byomailer::ServerError) { client(max_retries: 0).tags.list }
    assert_requested stub, times: 1
  end
end
