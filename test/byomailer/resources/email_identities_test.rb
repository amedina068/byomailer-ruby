require "test_helper"

class Byomailer::EmailIdentitiesTest < Byomailer::TestCase
  IDENTITY = { id: 1, email: "news@example.com", domain: "example.com", identity_status: "verified" }.freeze

  def test_list
    stub_api(:get, "/email-identities", query: { identity_status: "verified" }).to_return(cursor_page([ IDENTITY ]))

    assert_equal [ "news@example.com" ], client.email_identities.list(identity_status: "verified").map(&:email)
  end

  def test_find
    stub_api(:get, "/email-identities/1").to_return(json(data: IDENTITY))

    assert_equal "verified", client.email_identities.find(1).identity_status
  end
end
