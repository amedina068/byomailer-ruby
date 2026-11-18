require "test_helper"

class Byomailer::BlocksTest < Byomailer::TestCase
  BLOCK = { id: 5, name: "footer", html_content: "<p>Bye</p>" }.freeze

  def test_list_has_no_pages
    stub_api(:get, "/blocks").to_return(json(data: [ BLOCK ]))

    assert_equal [ "footer" ], client.blocks.list.map(&:name)
  end

  def test_find
    stub_api(:get, "/blocks/5").to_return(json(data: BLOCK))

    assert_equal "<p>Bye</p>", client.blocks.find(5).html_content
  end

  def test_create
    stub_api(:post, "/blocks").with(body: BLOCK.except(:id)).to_return(json({ data: BLOCK }, status: 201))

    assert_equal 5, client.blocks.create(name: "footer", html_content: "<p>Bye</p>").id
  end

  def test_update
    stub = stub_api(:patch, "/blocks/5").with(body: { name: "footer", html_content: "<p>See you</p>" }).to_return(json(data: BLOCK))

    client.blocks.update(5, name: "footer", html_content: "<p>See you</p>")

    assert_requested stub
  end

  def test_delete
    stub = stub_api(:delete, "/blocks/5").to_return(no_content)

    client.blocks.delete(5)

    assert_requested stub
  end
end
