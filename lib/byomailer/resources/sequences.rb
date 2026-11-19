module Byomailer
  # A sequence in a list: its status and counts, without the steps.
  class SequenceSummary < Record; end

  # One sequence with its steps, filters and content variables.
  class Sequence < Record; end

  class Sequences < Resource
    # A page of sequences. Live sequences come first, then the others by name.
    # status is "draft", "live" or "paused".
    def list(status: nil, search: nil, project: nil, per_page: nil, cursor: nil)
      page("/sequences", as: SequenceSummary, status:, search:, project:, per_page:, cursor:)
    end

    def find(id) = record(get("/sequences/#{id}"), as: Sequence)

    def stats(id) = record(get("/sequences/#{id}/stats"))

    def step(id, step_id) = record(get("/sequences/#{id}/steps/#{step_id}"))

    def step_stats(id, step_id) = record(get("/sequences/#{id}/steps/#{step_id}/stats"))

    # Replaces the audience filters of one step. An empty Array clears them.
    def replace_step_filters(id, step_id, filters)
      record(patch("/sequences/#{id}/steps/#{step_id}/filters", json: { filters: }))
    end

    def variables(id) = record(get("/sequences/#{id}/variables"))

    # Replaces all the saved defaults.
    def replace_variables(id, variables)
      record(patch("/sequences/#{id}/variables", json: { content_variables: variables }))
    end

    # Returns the CSV text with one row for each mail of the step.
    #
    #   csv = Byomailer.sequences.export_step_mails(3, 11, status: "bounced")
    #   File.write("bounced.csv", csv)
    #
    # The export always has the full history of the step. The app ignores
    # current_only, so the gem does not send it.
    def export_step_mails(id, step_id, **filters)
      if filters.key?(:current_only)
        warn "Byomailer: current_only is deprecated. The export always has the full history of the step.", category: :deprecated, uplevel: 1
        filters = filters.except(:current_only)
      end

      get("/sequences/#{id}/steps/#{step_id}/contact-mails/export", query: filters).to_s
    end
  end
end
