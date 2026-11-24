require "json"
require "net/http"
require "openssl"
require "time"
require "uri"

require "byomailer/version"
require "byomailer/errors"
require "byomailer/configuration"
require "byomailer/record"
require "byomailer/page"
require "byomailer/webhook"
require "byomailer/resource"
require "byomailer/resources/contacts"
require "byomailer/resources/lists"
require "byomailer/resources/topics"
require "byomailer/resources/tags"
require "byomailer/resources/newsletters"
require "byomailer/resources/sequences"
require "byomailer/resources/blocks"
require "byomailer/resources/email_templates"
require "byomailer/resources/email_identities"
require "byomailer/resources/email_logs"
require "byomailer/resources/projects"
require "byomailer/resources/webhook_endpoints"
require "byomailer/client"

# A client for one BYOMailer instance.
#
#   Byomailer.configure do |config|
#     config.url   = "https://mail.example.com"
#     config.token = "..."
#   end
#
#   Byomailer.contacts.add(3, "ana@example.com", name: "Ana")
#   Byomailer::Webhook.verify(request.raw_post, request.headers)
module Byomailer
  class << self
    def configure
      yield config
      reset!
    end

    def config
      @config ||= Configuration.new
    end

    def client
      @client ||= Client.new(**config.to_h)
    end

    def reset!
      @client = nil
    end

    def contacts          = client.contacts
    def lists             = client.lists
    def topics            = client.topics
    def tags              = client.tags
    def newsletters       = client.newsletters
    def sequences         = client.sequences
    def blocks            = client.blocks
    def email_templates   = client.email_templates
    def email_identities  = client.email_identities
    def email_logs        = client.email_logs
    def projects          = client.projects
    def webhook_endpoints = client.webhook_endpoints
  end
end

require "byomailer/railtie" if defined?(Rails::Railtie)
