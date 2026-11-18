require "test_helper"

class Byomailer::ClientTest < Byomailer::TestCase
  def test_sends_the_token_and_json_headers
    stub = stub_api(:get, "/tags")
      .with(headers: { "Authorization" => "Bearer #{TOKEN}", "Accept" => "application/json", "User-Agent" => "byomailer-ruby/#{Byomailer::VERSION}" })
      .to_return(json(data: []))

    client.tags.list

    assert_requested stub
  end

  def test_the_api_lives_under_api_v1_of_the_instance_url
    stub = stub_request(:get, "https://mail.example.com/api/v1/tags").to_return(json(data: []))

    client(url: "https://mail.example.com/").tags.list
    client(url: "https://mail.example.com/api/v1").tags.list

    assert_requested stub, times: 2
  end

  def test_sends_a_json_body
    stub = stub_api(:post, "/tags").with(body: { name: "VIP" }.to_json, headers: { "Content-Type" => "application/json" })
      .to_return(json({ data: { id: 1 } }, status: 201))

    client.tags.create(name: "VIP")

    assert_requested stub
  end

  def test_builds_a_laravel_query
    stub = stub_request(:get, "#{URL}/api/v1/contacts?lists[]=1&lists[]=2&include_unsubscribed=1&search=ana%20p")
      .to_return(cursor_page([]))

    client.contacts.list(lists: [ 1, 2 ], include_unsubscribed: true, search: "ana p")

    assert_requested stub
  end

  def test_request_returns_the_status_and_the_body
    stub_api(:get, "/tags").to_return(json(data: [ { id: 1 } ]))

    response = client.request(:get, "/tags")

    assert_equal 200, response.status
    assert_equal [ { "id" => 1 } ], response.body["data"]
  end

  def test_a_204_has_no_body
    stub_api(:delete, "/tags/1").to_return(no_content)

    assert_nil client.tags.delete(1)
  end

  def test_missing_url
    error = assert_raises(Byomailer::ConfigurationError) { Byomailer::Client.new(token: TOKEN).tags.list }

    assert_match "url", error.message
  end

  def test_missing_token
    error = assert_raises(Byomailer::ConfigurationError) { Byomailer::Client.new(url: URL).tags.list }

    assert_match "token", error.message
  end

  def test_inspect_hides_the_token
    refute_includes client.inspect, TOKEN
  end

  def test_the_default_client_uses_the_configuration
    Byomailer.configure do |config|
      config.url = URL
      config.token = TOKEN
      config.timeout = 5
    end

    assert_equal URL, Byomailer.client.url
    assert_equal 5, Byomailer.client.timeout
    assert_same Byomailer.client.tags, Byomailer.tags
  ensure
    Byomailer.instance_variable_set(:@config, nil)
    Byomailer.reset!
  end
end
