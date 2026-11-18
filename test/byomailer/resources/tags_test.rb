require "test_helper"

class Byomailer::TagsTest < Byomailer::TestCase
  def test_list_has_no_pages
    stub_api(:get, "/tags").to_return(json(data: [ { id: 4, name: "VIP", contacts_count: 12 } ]))

    assert_equal [ "VIP" ], client.tags.list.map(&:name)
  end

  def test_create
    stub_api(:post, "/tags").with(body: { name: "VIP" }).to_return(json({ data: { id: 4, name: "VIP" } }, status: 201))

    assert_equal 4, client.tags.create(name: "VIP").id
  end

  def test_rename
    stub_api(:patch, "/tags/4").with(body: { name: "Gold" }).to_return(json(data: { id: 4, name: "Gold" }))

    assert_equal "Gold", client.tags.rename(4, name: "Gold").name
  end

  def test_delete
    stub = stub_api(:delete, "/tags/4").to_return(no_content)

    client.tags.delete(4)

    assert_requested stub
  end
end
