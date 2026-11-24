module Byomailer
  class Lists < Resource
    def list(per_page: nil, cursor: nil) = page("/lists", per_page:, cursor:)

    def create(name:) = record(post("/lists", json: { name: }))

    def rename(id, name:) = record(patch("/lists/#{id}", json: { name: }, idempotent: true))

    # Deletes the list. The contacts on the list stay.
    def delete(id) = super("/lists/#{id}")
  end
end
