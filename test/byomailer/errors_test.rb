require "test_helper"

class Byomailer::ErrorsTest < Byomailer::TestCase
  {
    400 => Byomailer::ApiError,
    401 => Byomailer::AuthenticationError,
    403 => Byomailer::AuthorizationError,
    404 => Byomailer::NotFoundError,
    409 => Byomailer::ApiError,
    422 => Byomailer::ValidationError,
    429 => Byomailer::RateLimitError,
    500 => Byomailer::ServerError,
    503 => Byomailer::ServerError
  }.each do |status, error_class|
    define_method("test_status_#{status}_raises_#{error_class.name.split("::").last}") do
      stub_api(:get, "/contacts/1").to_return(json({ message: "Nope." }, status:))

      error = assert_raises(error_class) { client(max_retries: 0).contacts.find(1) }

      assert_equal status, error.status
      assert_equal "Nope.", error.message
      assert_kind_of Byomailer::Error, error
    end
  end

  def test_a_read_only_token_gets_an_authorization_error
    stub_api(:post, "/tags").to_return(json({ message: "You have read-only access." }, status: 403))

    error = assert_raises(Byomailer::AuthorizationError) { client.tags.create(name: "VIP") }

    assert_equal "You have read-only access.", error.message
  end

  def test_a_validation_error_has_the_field_errors
    stub_api(:post, "/lists/3/contacts").to_return(json({
      message: "The email field must be a valid email address.",
      errors: { email: [ "The email field must be a valid email address." ] }
    }, status: 422))

    error = assert_raises(Byomailer::ValidationError) { client.contacts.add("not-an-email", list: 3) }

    assert_equal({ "email" => [ "The email field must be a valid email address." ] }, error.errors)
  end

  def test_a_rate_limit_error_has_retry_after
    stub_api(:post, "/newsletters/7/test-mail").to_return(json({ message: "Too Many Attempts." }, status: 429, headers: { "Retry-After" => "42" }))

    error = assert_raises(Byomailer::RateLimitError) { client(max_retries: 0).newsletters.send_test_email(7) }

    assert_equal 42, error.retry_after
  end

  def test_retry_after_as_an_http_date
    date = (Time.now + 30).httpdate
    stub_api(:get, "/tags").to_return(json({}, status: 429, headers: { "Retry-After" => date }))

    error = assert_raises(Byomailer::RateLimitError) { client(max_retries: 0).tags.list }

    assert_includes 29..30, error.retry_after
  end

  def test_a_body_that_is_not_json
    stub_api(:get, "/tags").to_return(status: 502, body: "<html>Bad gateway</html>", headers: { "Content-Type" => "text/html" })

    error = assert_raises(Byomailer::ServerError) { client(max_retries: 0).tags.list }

    assert_equal "BYOMailer returned HTTP 502", error.message
    assert_equal "<html>Bad gateway</html>", error.body
  end

  def test_a_connection_error
    stub_api(:get, "/tags").to_raise(Errno::ECONNREFUSED)

    error = assert_raises(Byomailer::ConnectionError) { client(max_retries: 0).tags.list }

    assert_match "Connection refused", error.message
    assert_kind_of Byomailer::Error, error
  end

  def test_a_tls_error_is_a_connection_error
    stub_api(:get, "/tags").to_raise(OpenSSL::SSL::SSLError.new("certificate verify failed"))

    assert_raises(Byomailer::ConnectionError) { client.tags.list }
  end
end
