require "test_helper"

class Byomailer::SequencesTest < Byomailer::TestCase
  STEP = { id: 11, sequence_id: 3, delay_days: 2, status: "live", filters: [], message: { subject: "Welcome" } }.freeze

  def test_list
    stub_api(:get, "/sequences", query: { status: "live" }).to_return(cursor_page([ { id: 3, name: "Welcome", steps_count: 2 } ]))

    assert_equal [ "Welcome" ], client.sequences.list(status: "live").map(&:name)
  end

  def test_find
    stub_api(:get, "/sequences/3").to_return(json(data: { id: 3, name: "Welcome", steps: [ STEP ] }))

    assert_equal "Welcome", client.sequences.find(3).steps.first.message.subject
  end

  def test_stats
    stub_api(:get, "/sequences/3/stats").to_return(json(data: { id: 3, stats: { sent: 10 }, mail_metrics: {} }))

    assert_equal 10, client.sequences.stats(3).stats.sent
  end

  def test_step
    stub_api(:get, "/sequences/3/steps/11").to_return(json(data: STEP))

    assert_equal 2, client.sequences.step(3, 11).delay_days
  end

  def test_step_stats
    stub_api(:get, "/sequences/3/steps/11/stats").to_return(json(data: { id: 11, stats: { opened: 4 } }))

    assert_equal 4, client.sequences.step_stats(3, 11).stats.opened
  end

  def test_replace_step_filters
    filters = [ { category: "tags", mode: "none", values: [ 5 ] } ]
    stub = stub_api(:patch, "/sequences/3/steps/11/filters").with(body: { filters: }).to_return(json(data: STEP))

    client.sequences.replace_step_filters(3, 11, filters)

    assert_requested stub
  end

  def test_variables
    stub_api(:get, "/sequences/3/variables").to_return(json(data: { sequence_id: 3, detected_variables: [ "plan" ], content_variables: {} }))

    assert_equal [ "plan" ], client.sequences.variables(3).detected_variables
  end

  def test_replace_variables
    stub = stub_api(:patch, "/sequences/3/variables").with(body: { content_variables: { plan: "free" } })
      .to_return(json(data: { sequence_id: 3, detected_variables: [ "plan" ], content_variables: { plan: "free" } }))

    client.sequences.replace_variables(3, { plan: "free" })

    assert_requested stub
  end

  def test_export_step_mails_returns_the_csv_text
    csv = "id,email,status\n1,ana@example.com,bounced\n"
    stub_request(:get, "#{URL}/api/v1/sequences/3/steps/11/contact-mails/export?status=bounced&current_only=1&sent_after=2026-11-01T00:00:00Z")
      .to_return(status: 200, body: csv, headers: { "Content-Type" => "text/csv; charset=UTF-8" })

    result = client.sequences.export_step_mails(3, 11, status: "bounced", current_only: true, sent_after: Time.utc(2026, 11, 1))

    assert_equal csv, result
    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_export_of_an_empty_step_is_an_empty_string
    stub_api(:get, "/sequences/3/steps/11/contact-mails/export").to_return(status: 200, body: "", headers: { "Content-Type" => "text/csv" })

    assert_equal "", client.sequences.export_step_mails(3, 11)
  end
end
