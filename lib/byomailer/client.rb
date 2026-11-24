module Byomailer
  # A client for one BYOMailer instance. Byomailer.client is the default
  # client, built from Byomailer.config. Make your own to talk to more than one
  # instance:
  #
  #   client = Byomailer::Client.new(url: "https://mail.example.com", token: "...")
  #   client.contacts.list
  class Client
    # The status and the parsed body of one response.
    Response = Data.define(:status, :body)

    # The connection did not open, so the server did not get the request:
    # a DNS failure, a refused connection or a connect timeout.
    BEFORE_SEND = [ SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, Net::OpenTimeout ].freeze

    # The server possibly got the request.
    AFTER_SEND = [ Net::ReadTimeout, Net::WriteTimeout, Errno::ECONNRESET, Errno::EPIPE, Errno::ETIMEDOUT, EOFError ].freeze

    # A repeat of a request with one of these methods does nothing new.
    IDEMPOTENT_METHODS = %i[ get head put delete ].freeze

    BASE_DELAY = 0.5
    MAX_DELAY = 8
    MAX_RETRY_AFTER = 60

    attr_reader :url, :timeout, :max_retries

    def initialize(url: nil, token: nil, timeout: 30, max_retries: 2)
      @url = url.to_s.chomp("/").delete_suffix("/api/v1")
      @token = token
      @timeout = timeout
      @max_retries = max_retries
    end

    def contacts          = @contacts ||= Contacts.new(self)
    def lists             = @lists ||= Lists.new(self)
    def topics            = @topics ||= Topics.new(self)
    def tags              = @tags ||= Tags.new(self)
    def newsletters       = @newsletters ||= Newsletters.new(self)
    def sequences         = @sequences ||= Sequences.new(self)
    def blocks            = @blocks ||= Blocks.new(self)
    def email_templates   = @email_templates ||= EmailTemplates.new(self)
    def email_identities  = @email_identities ||= EmailIdentities.new(self)
    def email_logs        = @email_logs ||= EmailLogs.new(self)
    def projects          = @projects ||= Projects.new(self)
    def webhook_endpoints = @webhook_endpoints ||= WebhookEndpoints.new(self)

    # Sends one request to {url}/api/v1{path} and returns a Response.
    #
    # Retries a 429 and a connection error before the send for each request,
    # because the server did not do it. Retries a 5xx, a read timeout or a
    # reset after the send only when the request is idempotent: a GET, HEAD,
    # PUT or DELETE, or an operation of the idempotent list that passes
    # idempotent: true.
    def request(method, path, query: nil, json: nil, idempotent: IDEMPOTENT_METHODS.include?(method))
      attempt = 0

      begin
        attempt += 1
        response = transmit(method, path, query:, json:)
        raise ApiError.for(response) unless response.is_a?(Net::HTTPSuccess)

        Response.new(status: response.code.to_i, body: parse(response))
      rescue RateLimitError, ServerError => error
        raise unless attempt <= max_retries && retryable?(error, idempotent)

        pause delay(attempt, error.retry_after)
        retry
      rescue *BEFORE_SEND, *AFTER_SEND => error
        unless attempt <= max_retries && (idempotent || BEFORE_SEND.any? { |kind| error.is_a?(kind) })
          raise ConnectionError, "BYOMailer request failed: #{error.message}"
        end

        pause delay(attempt)
        retry
      rescue OpenSSL::SSL::SSLError => error
        raise ConnectionError, "BYOMailer request failed: #{error.message}"
      end
    end

    def inspect
      "#<#{self.class.name} url=#{url.inspect}>"
    end

    private
      def transmit(method, path, query:, json:)
        raise ConfigurationError, "Set the BYOMailer url, for example https://mail.example.com" if url.empty?
        raise ConfigurationError, "Set the BYOMailer token" if @token.to_s.empty?

        uri = URI("#{url}/api/v1#{path}")
        uri.query = to_query(query) if query && !query.empty?

        request = Net::HTTP.const_get(method.to_s.capitalize).new(uri)
        request["Authorization"] = "Bearer #{@token}"
        request["Accept"] = "application/json"
        request["User-Agent"] = "byomailer-ruby/#{VERSION}"

        if json
          request["Content-Type"] = "application/json"
          request.body = JSON.generate(json)
        end

        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                        open_timeout: timeout, read_timeout: timeout, write_timeout: timeout) do |http|
          http.request(request)
        end
      end

      # A 204 has no body. The CSV export is text, not JSON.
      def parse(response)
        body = response.body.to_s.dup.force_encoding(Encoding::UTF_8)
        return if body.empty?

        response.content_type.to_s.include?("json") ? JSON.parse(body) : body
      end

      def retryable?(error, idempotent)
        (error.is_a?(RateLimitError) || idempotent) && (error.retry_after.nil? || error.retry_after <= MAX_RETRY_AFTER)
      end

      # Exponential backoff with jitter. A Retry-After value wins.
      def delay(attempt, retry_after = nil)
        return retry_after if retry_after

        backoff = [ BASE_DELAY * (2**(attempt - 1)), MAX_DELAY ].min
        backoff / 2 + rand * backoff / 2
      end

      def pause(seconds)
        sleep seconds
      end

      # Builds the query string that Laravel reads: tags[]=1&tags[]=2, true as 1
      # and a Time as ISO 8601.
      def to_query(params)
        params.flat_map do |key, value|
          case value
          when Array then value.map { |item| pair("#{key}[]", item) }
          else [ pair(key, value) ]
          end
        end.join("&")
      end

      def pair(key, value)
        value = case value
        when true  then 1
        when false then 0
        when Time  then value.iso8601
        else value
        end

        "#{URI.encode_www_form_component(key.to_s)}=#{URI.encode_www_form_component(value.to_s)}"
      end
  end
end
