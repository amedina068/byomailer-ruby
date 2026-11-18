$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)

require "byomailer"
require "minitest/autorun"

# Talks to a real BYOMailer instance. The tests only read: they list
# contacts, lists and tags. They never send email, never schedule a
# newsletter and never send a webhook test delivery.
#
#   BYOMAILER_TEST_URL=https://mail.example.com BYOMAILER_TEST_TOKEN=... bin/rake test:integration
class Byomailer::LiveTest < Minitest::Test
  def setup
    skip "Set BYOMAILER_TEST_URL and BYOMAILER_TEST_TOKEN to run the integration tests" unless ENV["BYOMAILER_TEST_URL"] && ENV["BYOMAILER_TEST_TOKEN"]

    @client = Byomailer::Client.new(url: ENV["BYOMAILER_TEST_URL"], token: ENV["BYOMAILER_TEST_TOKEN"])
  end

  def test_list_contacts
    page = @client.contacts.list(per_page: 5)

    assert_kind_of Array, page.records
    page.each { |contact| assert_kind_of String, contact.email }
  end

  def test_list_lists
    page = @client.lists.list(per_page: 5)

    page.each { |list| assert_kind_of Integer, list.id }
  end

  def test_list_tags
    @client.tags.list.each { |tag| assert_kind_of String, tag.name }
  end
end
