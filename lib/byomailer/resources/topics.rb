module Byomailer
  class Topics < Resource
    # All the topics of a list. This list has no pages.
    def list(list:) = Record.wrap(get("/lists/#{list}/topics")["data"])

    def create(list:, name:, description: nil)
      record(post("/lists/#{list}/topics", json: { name:, description: }))
    end

    # Replaces the name and the description. A topic without a description gets none.
    def update(id, list:, name:, description: nil)
      record(patch("/lists/#{list}/topics/#{id}", json: { name:, description: }))
    end

    def delete(id, list:) = super("/lists/#{list}/topics/#{id}")
  end
end
