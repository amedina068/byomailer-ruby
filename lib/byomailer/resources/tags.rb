module Byomailer
  class Tags < Resource
    # All the tags, newest first. This list has no pages.
    def list = Record.wrap(get("/tags")["data"])

    def create(name:) = record(post("/tags", json: { name: }))

    def rename(id, name:) = record(patch("/tags/#{id}", json: { name: }, idempotent: true))

    # Deletes the tag and removes it from each contact.
    def delete(id) = super("/tags/#{id}")
  end
end
