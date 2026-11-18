require "test_helper"

class Byomailer::EmailLogsTest < Byomailer::TestCase
  LOG = { id: 9, operation: "send", recipient: "ana@example.com", status: "bounced" }.freeze

  def test_list
    stub_api(:get, "/email-logs", query: { status: "bounced", operation: "send", recipient: "ana" }).to_return(cursor_page([ LOG ]))

    assert_equal [ 9 ], client.email_logs.list(status: "bounced", operation: "send", recipient: "ana").map(&:id)
  end

  def test_find
    stub_api(:get, "/email-logs/9").to_return(json(data: LOG))

    assert_equal "ana@example.com", client.email_logs.find(9).recipient
  end
end
