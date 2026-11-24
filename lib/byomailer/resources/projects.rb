module Byomailer
  class Projects < Resource
    def list(per_page: nil, cursor: nil) = page("/projects", per_page:, cursor:)

    def find(id) = record(get("/projects/#{id}"))

    def create(name:) = record(post("/projects", json: { name: }))

    def rename(id, name:) = record(patch("/projects/#{id}", json: { name: }, idempotent: true))

    # Deletes the project. Its newsletters, sequences and automations stay.
    def delete(id) = super("/projects/#{id}")
  end
end
