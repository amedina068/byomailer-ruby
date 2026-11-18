require "test_helper"

class Byomailer::PaginationTest < Byomailer::TestCase
  def test_a_page_has_records_and_meta
    stub_api(:get, "/lists").to_return(cursor_page([ { id: 2, name: "Buyers" }, { id: 1, name: "Customers" } ], next_cursor: "c2"))

    page = client.lists.list

    assert_equal [ "Buyers", "Customers" ], page.map(&:name)
    assert_equal "c2", page.next_cursor
    assert_predicate page, :next_page?
  end

  def test_next_page_sends_the_cursor_and_keeps_the_query
    stub_api(:get, "/contacts", query: { tags: [ "4" ], per_page: "2" }).to_return(cursor_page([ { id: 3 }, { id: 2 } ], next_cursor: "c2"))
    second = stub_api(:get, "/contacts", query: { tags: [ "4" ], per_page: "2", cursor: "c2" }).to_return(cursor_page([ { id: 1 } ]))

    page = client.contacts.list(tags: [ 4 ], per_page: 2).next_page

    assert_equal [ 1 ], page.map(&:id)
    refute_predicate page, :next_page?
    assert_nil page.next_page
    assert_requested second
  end

  def test_each_record_walks_every_page
    stub_api(:get, "/projects", query: { per_page: "100" }).to_return(cursor_page([ { id: 3 }, { id: 2 } ], next_cursor: "c2"))
    stub_api(:get, "/projects", query: { per_page: "100", cursor: "c2" }).to_return(cursor_page([ { id: 1 } ], next_cursor: "c3"))
    stub_api(:get, "/projects", query: { per_page: "100", cursor: "c3" }).to_return(cursor_page([]))

    ids = []
    client.projects.list(per_page: 100).each_record { |project| ids << project.id }

    assert_equal [ 3, 2, 1 ], ids
  end

  def test_each_record_without_a_block_is_an_enumerator
    stub_api(:get, "/email-logs").to_return(cursor_page([ { id: 2 } ], next_cursor: "c2"))
    second = stub_api(:get, "/email-logs", query: { cursor: "c2" }).to_return(cursor_page([ { id: 1 } ]))

    records = client.email_logs.list.each_record

    assert_equal 2, records.first.id
    assert_not_requested second
    assert_equal [ 2, 1 ], records.map(&:id)
  end

  def test_a_list_can_start_at_a_cursor
    stub = stub_api(:get, "/lists", query: { cursor: "c9" }).to_return(cursor_page([]))

    client.lists.list(cursor: "c9")

    assert_requested stub
  end
end
