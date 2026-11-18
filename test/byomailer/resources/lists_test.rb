require "test_helper"

class Byomailer::ListsTest < Byomailer::TestCase
  def test_list
    stub_api(:get, "/lists", query: { per_page: "50" }).to_return(cursor_page([ { id: 3, name: "Customers", opt_in_enabled: false } ]))

    assert_equal [ "Customers" ], client.lists.list(per_page: 50).map(&:name)
  end

  def test_create
    stub_api(:post, "/lists").with(body: { name: "Customers" }).to_return(json({ data: { id: 3, name: "Customers" } }, status: 201))

    assert_equal 3, client.lists.create(name: "Customers").id
  end

  def test_rename
    stub_api(:patch, "/lists/3").with(body: { name: "Buyers" }).to_return(json(data: { id: 3, name: "Buyers" }))

    assert_equal "Buyers", client.lists.rename(3, name: "Buyers").name
  end

  def test_delete
    stub = stub_api(:delete, "/lists/3").to_return(no_content)

    assert_nil client.lists.delete(3)
    assert_requested stub
  end
end
