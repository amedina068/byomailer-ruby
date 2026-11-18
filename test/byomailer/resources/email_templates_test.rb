require "test_helper"

class Byomailer::EmailTemplatesTest < Byomailer::TestCase
  TEMPLATE = { id: 2, name: "Plain", html_content: "<html></html>", is_default: true, archived_at: nil }.freeze

  def test_list
    stub_api(:get, "/email-templates", query: { archived: "0", is_default: "1" }).to_return(cursor_page([ TEMPLATE ]))

    assert_equal [ "Plain" ], client.email_templates.list(archived: false, is_default: true).map(&:name)
  end

  def test_find
    stub_api(:get, "/email-templates/2").to_return(json(data: TEMPLATE))

    assert client.email_templates.find(2).is_default
  end

  def test_default
    stub_api(:get, "/email-templates/default").to_return(json(data: TEMPLATE))

    assert_equal 2, client.email_templates.default.id
  end

  def test_no_default_is_not_found
    stub_api(:get, "/email-templates/default").to_return(json({ message: "No default template." }, status: 404))

    assert_raises(Byomailer::NotFoundError) { client.email_templates.default }
  end
end
