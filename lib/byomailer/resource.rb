module Byomailer
  class Resource
    def initialize(client)
      @client = client
    end

    def inspect
      "#<#{self.class.name}>"
    end

    private
      attr_reader :client

      def get(path, **options)    = client.request(:get, path, **options).body
      def post(path, **options)   = client.request(:post, path, **options).body
      def patch(path, **options)  = client.request(:patch, path, **options).body
      def delete(path, **options) = client.request(:delete, path, **options).body

      def record(body) = Record.wrap(body["data"])

      # A cursor list. Each next page keeps the query and changes only the cursor.
      def page(path, cursor: nil, **query)
        body = get(path, query: { **query, cursor: }.compact)

        Page.new(body["data"], body["meta"]) { |next_cursor| page(path, **query, cursor: next_cursor) }
      end
  end
end
