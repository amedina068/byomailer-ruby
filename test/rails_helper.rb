$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rails"
require "action_controller/railtie"
require "byomailer"
require "tmpdir"
require "fileutils"

# A minimal Rails app. Its credentials hold the byomailer settings, and an
# initializer changes one of them.
DUMMY_ROOT = Dir.mktmpdir("byomailer-rails")
at_exit { FileUtils.rm_rf(DUMMY_ROOT) }
FileUtils.mkdir_p("#{DUMMY_ROOT}/config/initializers")
File.write("#{DUMMY_ROOT}/config/initializers/byomailer.rb", "Byomailer.configure { |config| config.timeout = 5 }\n")

File.write("#{DUMMY_ROOT}/config/test.key", ActiveSupport::EncryptedConfiguration.generate_key)
ActiveSupport::EncryptedConfiguration.new(
  config_path: "#{DUMMY_ROOT}/config/test.yml.enc", key_path: "#{DUMMY_ROOT}/config/test.key",
  env_key: "BYOMAILER_TEST_MASTER_KEY", raise_if_missing_key: true
).write(<<~YAML)
  byomailer:
    url: https://mail.example.com
    token: credentials-token
    webhook_secret: whsec_credentials
YAML

class Dummy < Rails::Application
  config.root = DUMMY_ROOT
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "0" * 64
  config.hosts.clear
  config.credentials.content_path = Pathname("#{DUMMY_ROOT}/config/test.yml.enc")
  config.credentials.key_path = Pathname("#{DUMMY_ROOT}/config/test.key")

  routes.append do
    post "/webhooks/byomailer" => "byomailer_webhooks#create"
  end
end

# The controller of the README.
class ByomailerWebhooksController < ActionController::API
  def create
    event = Byomailer::Webhook.verify(request.raw_post, request.headers)
    render plain: event.event
  rescue Byomailer::WebhookVerificationError => error
    render plain: error.reason.to_s, status: :bad_request
  end
end

Dummy.initialize!

require "minitest/autorun"
require "rails/test_help"
