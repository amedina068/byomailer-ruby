require "test_helper"

class Byomailer::SequencesTest < Byomailer::TestCase
  STEP = { id: 11, sequence_id: 3, delay_days: 2, status: "live", filters: [], message: { subject: "Welcome" } }.freeze

  SUMMARY = { id: 3, name: "Welcome", status: "live", steps_count: 2, contacts_count: 10, completed_count: 4, active_count: 6, project_ids: [ 1 ] }.freeze
  SEQUENCE = SUMMARY.merge(steps: [ STEP ], segment_id: nil, filters: [ { category: "tags", mode: "any", values: [ 5 ] } ],
    content_variables: { plan: "free" }, created_at: "2026-11-01T10:00:00.000000Z").freeze

  def test_list_returns_summaries
    stub_api(:get, "/sequences", query: { status: "live" }).to_return(cursor_page([ SUMMARY ]))

    sequence = client.sequences.list(status: "live").first

    assert_instance_of Byomailer::SequenceSummary, sequence
    assert_equal [ 4, 6 ], [ sequence.completed_count, sequence.active_count ]
  end

  def test_list_filters_by_each_status
    %w[ draft live paused ].each do |status|
      stub = stub_api(:get, "/sequences", query: { status: }).to_return(cursor_page([]))

      client.sequences.list(status:)

      assert_requested stub
    end
  end

  def test_each_page_of_the_list_has_summaries
    stub_api(:get, "/sequences").to_return(cursor_page([ SUMMARY ], next_cursor: "c2"))
    stub_api(:get, "/sequences", query: { cursor: "c2" }).to_return(cursor_page([ SUMMARY.merge(id: 2) ]))

    assert_equal [ Byomailer::SequenceSummary ], client.sequences.list.each_record.map(&:class).uniq
  end

  def test_find_returns_the_sequence_with_its_steps_filters_and_variables
    stub_api(:get, "/sequences/3").to_return(json(data: SEQUENCE))

    sequence = client.sequences.find(3)

    assert_instance_of Byomailer::Sequence, sequence
    assert_equal "Welcome", sequence.steps.first.message.subject
    assert_equal "any", sequence.filters.first.mode
    assert_equal "free", sequence.content_variables.plan
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
    stub_request(:get, "#{URL}/api/v1/sequences/3/steps/11/contact-mails/export?status=bounced&sent_after=2026-11-01T00:00:00Z")
      .to_return(status: 200, body: csv, headers: { "Content-Type" => "text/csv; charset=UTF-8" })

    result = client.sequences.export_step_mails(3, 11, status: "bounced", sent_after: Time.utc(2026, 11, 1))

    assert_equal csv, result
    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_export_step_mails_does_not_send_the_deprecated_current_only
    stub = stub_request(:get, "#{URL}/api/v1/sequences/3/steps/11/contact-mails/export?status=bounced").to_return(status: 200, body: "")

    with_deprecation_warnings do
      assert_output(nil, /current_only is deprecated/) { client.sequences.export_step_mails(3, 11, status: "bounced", current_only: true) }
    end

    assert_requested stub
  end

  def test_export_of_an_empty_step_is_an_empty_string
    stub_api(:get, "/sequences/3/steps/11/contact-mails/export").to_return(status: 200, body: "", headers: { "Content-Type" => "text/csv" })

    assert_equal "", client.sequences.export_step_mails(3, 11)
  end

  private
    def with_deprecation_warnings
      enabled = Warning[:deprecated]
      Warning[:deprecated] = true
      yield
    ensure
      Warning[:deprecated] = enabled
    end
end
