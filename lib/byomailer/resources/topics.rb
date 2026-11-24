module Byomailer
  class Topics < Resource
    # All the topics of a list. This list has no pages.
    def list(list_id) = Record.wrap(get("/lists/#{list_id}/topics")["data"])

    def create(list_id, name:, description: nil)
      record(post("/lists/#{list_id}/topics", json: { name:, description: }))
    end

    # Replaces the name and the description. A topic without a description gets none.
    def update(list_id, topic_id, name:, description: nil)
      record(patch("/lists/#{list_id}/topics/#{topic_id}", json: { name:, description: }, idempotent: true))
    end

    def delete(list_id, topic_id) = super("/lists/#{list_id}/topics/#{topic_id}")
  end
end
