module Byomailer
  # The settings of the default client. Each value falls back to an
  # environment variable: BYOMAILER_URL, BYOMAILER_TOKEN and BYOMAILER_WEBHOOK_SECRET.
  # In a Rails app, the Railtie also reads Rails.application.credentials.byomailer.
  class Configuration
    attr_writer :url, :token, :webhook_secret
    attr_accessor :timeout, :max_retries

    def initialize
      @timeout = 30
      @max_retries = 2
    end

    def url            = @url || ENV["BYOMAILER_URL"]
    def token          = @token || ENV["BYOMAILER_TOKEN"]
    def webhook_secret = @webhook_secret || ENV["BYOMAILER_WEBHOOK_SECRET"]

    # Copies the known keys of a Hash, for example the byomailer credentials.
    def merge!(settings)
      settings.to_h.each do |key, value|
        public_send("#{key}=", value) if respond_to?("#{key}=")
      end
      self
    end

    # The settings of a client. The webhook secret is not one of them.
    def to_h
      { url:, token:, timeout:, max_retries: }
    end

    def inspect
      "#<#{self.class.name} url=#{url.inspect} timeout=#{timeout} max_retries=#{max_retries}>"
    end
  end
end
