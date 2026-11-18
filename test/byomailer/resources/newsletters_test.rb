require "test_helper"

class Byomailer::NewslettersTest < Byomailer::TestCase
  NEWSLETTER = { id: 7, title: "November news", status: "draft", metrics: { total: 0, open_rate: 0.0 } }.freeze
  FILTERS = [ { category: "tags", mode: "any", values: [ 4 ] } ].freeze

  def test_list
    stub_api(:get, "/newsletters", query: { status: "sent", project: "2" }).to_return(cursor_page([ NEWSLETTER ]))

    assert_equal [ 7 ], client.newsletters.list(status: "sent", project: 2).map(&:id)
  end

  def test_find
    stub_api(:get, "/newsletters/7").to_return(json(data: NEWSLETTER))

    assert_in_delta 0.0, client.newsletters.find(7).metrics.open_rate
  end

  def test_create
    stub_api(:post, "/newsletters")
      .with(body: { title: "November news", subject: "News", html_content: "<p>Hello</p>", filters: FILTERS })
      .to_return(json({ data: NEWSLETTER }, status: 201))

    newsletter = client.newsletters.create(title: "November news", subject: "News", html_content: "<p>Hello</p>", filters: FILTERS)

    assert_equal "draft", newsletter.status
  end

  def test_update
    stub_api(:patch, "/newsletters/7").with(body: { status: "live", scheduled_at: "2026-12-01T09:00:00Z" })
      .to_return(json(data: NEWSLETTER.merge(status: "scheduled")))

    assert_equal "scheduled", client.newsletters.update(7, status: "live", scheduled_at: "2026-12-01T09:00:00Z").status
  end

  def test_delete
    stub = stub_api(:delete, "/newsletters/7").to_return(no_content)

    client.newsletters.delete(7)

    assert_requested stub
  end

  def test_count_recipients
    stub_api(:post, "/newsletters/contacts/preview").with(body: { filters: FILTERS }).to_return(json(count: 128))

    assert_equal 128, client.newsletters.count_recipients(filters: FILTERS)
  end

  def test_send_test_email
    stub_api(:post, "/newsletters/7/test-mail").to_return(json(message: "Test email sent to dev@example.com", sent_to: "dev@example.com"))

    assert_equal "dev@example.com", client.newsletters.send_test_email(7).sent_to
  end

  def test_pick_winner
    stub_api(:post, "/newsletters/7/ab-winner").with(body: { winner_variant: "b" })
      .to_return(json(data: NEWSLETTER.merge(status: "sent", ab_test_winner_variant: "b")))

    assert_equal "b", client.newsletters.pick_winner(7, :b).ab_test_winner_variant
  end

  def test_variables
    stub_api(:get, "/newsletters/7/variables")
      .to_return(json(data: { newsletter_id: 7, detected_variables: [ "first_name" ], content_variables: { first_name: "" } }))

    assert_equal [ "first_name" ], client.newsletters.variables(7).detected_variables
  end

  def test_replace_variables
    stub_api(:patch, "/newsletters/7/variables").with(body: { content_variables: { first_name: "friend" } })
      .to_return(json(data: { newsletter_id: 7, detected_variables: [ "first_name" ], content_variables: { first_name: "friend" } }))

    assert_equal "friend", client.newsletters.replace_variables(7, first_name: "friend").content_variables.first_name
  end
end
