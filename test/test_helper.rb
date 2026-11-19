$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "byomailer"
require "minitest/autorun"
require "webmock/minitest"

module Byomailer
  class TestCase < Minitest::Test
    URL = "https://mail.example.com"
    TOKEN = "test-token"

    def setup
      WebMock.disable_net_connect!
    end

    # A client that records each pause instead of sleeping.
    def client(**options)
      Client.new(url: URL, token: TOKEN, **options).tap do |client|
        client.instance_variable_set(:@pauses, [])
        def client.pauses = @pauses
        def client.pause(seconds) = @pauses << seconds
      end
    end

    def stub_api(method, path, query: nil)
      stub = stub_request(method, "#{URL}/api/v1#{path}")
      query ? stub.with(query:) : stub
    end

    def json(body = nil, status: 200, headers: {}, **fields)
      { status:, body: JSON.generate(body || fields), headers: { "Content-Type" => "application/json", **headers } }
    end

    def no_content
      { status: 204, body: "" }
    end

    # A cursor page, like a Laravel cursorPaginate response.
    def cursor_page(data, next_cursor: nil)
      links = { first: nil, last: nil, prev: nil, next: next_cursor && "#{URL}/api/v1?cursor=#{next_cursor}" }

      json(data:, links:, meta: { path: "#{URL}/api/v1", per_page: 25, next_cursor:, prev_cursor: nil })
    end
  end
end
