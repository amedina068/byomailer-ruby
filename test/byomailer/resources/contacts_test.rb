require "test_helper"

class Byomailer::ContactsTest < Byomailer::TestCase
  CONTACT = { id: 42, uuid: "9b2f6c1e", email: "ana@example.com", name: "Ana", extra_attributes: { company: "Acme" }, tags: [], lists: [], topics: [], sequences: [] }.freeze

  def test_list
    stub_api(:get, "/contacts", query: { tags: [ "4" ], topics: [ "9" ], search: "ana" }).to_return(cursor_page([ CONTACT ]))

    assert_equal [ "ana@example.com" ], client.contacts.list(tags: [ 4 ], topics: [ 9 ], search: "ana").map(&:email)
  end

  def test_find
    stub_api(:get, "/contacts/42").to_return(json(data: CONTACT))

    assert_equal "Acme", client.contacts.find(42).extra_attributes.company
  end

  def test_add_a_new_contact_sends_the_attributes_at_the_top_level
    stub = stub_api(:post, "/lists/3/contacts")
      .with(body: { company: "Acme", plan: "pro", email: "ana@example.com", name: "Ana", tags: [ "vip" ] })
      .to_return(json({ data: CONTACT }, status: 201))

    contact = client.contacts.add("ana@example.com", list: 3, name: "Ana", tags: [ "vip" ], attributes: { company: "Acme", plan: "pro" })

    assert_predicate contact, :created?
    assert_equal 42, contact.id
    assert_requested stub
  end

  def test_add_an_existing_contact
    stub_api(:post, "/lists/3/contacts").with(body: { email: "ana@example.com" }).to_return(json(data: CONTACT))

    refute_predicate client.contacts.add("ana@example.com", list: 3), :created?
  end

  def test_update_uses_patch_and_sends_only_the_given_fields
    stub = stub_api(:patch, "/contacts/42")
      .with(body: { plan: "pro", remove_tags: [ "trial" ] })
      .to_return(json(data: CONTACT))

    client.contacts.update(42, remove_tags: [ "trial" ], attributes: { plan: "pro" })

    assert_requested stub
  end

  def test_unsubscribe
    stub_api(:post, "/contacts/42/unsubscribe").to_return(json(data: CONTACT.merge(unsubscribed_at: "2026-11-18T10:00:00.000000Z")))

    assert_equal "2026-11-18T10:00:00.000000Z", client.contacts.unsubscribe(42).unsubscribed_at
  end

  def test_remove_from_a_list
    stub = stub_api(:delete, "/lists/3/contacts/42").to_return(json(data: CONTACT))

    assert_equal 42, client.contacts.remove(42, list: 3).id
    assert_requested stub
  end
end
