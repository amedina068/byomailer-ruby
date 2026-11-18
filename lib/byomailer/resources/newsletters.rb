module Byomailer
  class Newsletters < Resource
    # A page of newsletters, newest first. status is draft, scheduled, queued,
    # ab_testing, sent or failed. project is a project ID.
    def list(status: nil, search: nil, project: nil, per_page: nil, cursor: nil)
      page("/newsletters", status:, search:, project:, per_page:, cursor:)
    end

    def find(id) = record(get("/newsletters/#{id}"))

    # Creates a draft. status: "live" with scheduled_at schedules the send.
    #
    #   Byomailer.newsletters.create(title: "November news", subject: "News", html_content: "<p>Hello</p>")
    def create(**attributes) = record(post("/newsletters", json: attributes))

    # Changes only the given fields of a draft or scheduled newsletter.
    def update(id, **attributes) = record(patch("/newsletters/#{id}", json: attributes))

    # Deletes a draft. A newsletter with another status raises ValidationError.
    def delete(id) = super("/newsletters/#{id}")

    # The number of contacts that match the audience filters. Nothing is saved,
    # so a retry is safe. The limit is 30 requests a minute.
    def count_recipients(filters: [])
      post("/newsletters/contacts/preview", json: { filters: }, idempotent: true)["count"]
    end

    # Sends the newsletter to the email address of the token user.
    # The limit is 5 requests a minute.
    def send_test_email(id) = Record.wrap(post("/newsletters/#{id}/test-mail"))

    # Sends variant "a" or "b" to the rest of the audience of an A/B test.
    def pick_winner(id, variant)
      record(post("/newsletters/#{id}/ab-winner", json: { winner_variant: variant.to_s }))
    end

    # The variables that the content uses and the saved default of each one.
    def variables(id) = record(get("/newsletters/#{id}/variables"))

    # Replaces all the saved defaults.
    #
    #   Byomailer.newsletters.replace_variables(7, first_name: "friend")
    def replace_variables(id, variables)
      record(patch("/newsletters/#{id}/variables", json: { content_variables: variables }))
    end
  end
end
