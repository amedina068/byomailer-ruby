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

  def test_retries_a_patch_after_a_server_error
    stub = stub_api(:patch, "/lists/3").to_return(json({}, status: 502)).then.to_return(json(data: { id: 3 }))

    client.lists.rename(3, name: "Buyers")

    assert_requested stub, times: 2
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

    assert_equal "dev@example.com", client.newsletters.send_test_email(7).sent_to
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

  def test_retries_a_post_after_a_connection_error_before_the_request_was_sent
    stub = stub_api(:post, "/lists").to_raise(Errno::ECONNREFUSED).then.to_raise(Net::OpenTimeout)
      .then.to_return(json({ data: { id: 3 } }, status: 201))

    assert_equal 3, client.lists.create(name: "Customers").id
    assert_requested stub, times: 3
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
