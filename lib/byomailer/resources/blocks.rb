module Byomailer
  class Blocks < Resource
    # All the blocks, newest first. This list has no pages.
    def list = Record.wrap(get("/blocks")["data"])

    def find(id) = record(get("/blocks/#{id}"))

    # name has lowercase letters, numbers and underscores only.
    def create(name:, html_content:) = record(post("/blocks", json: { name:, html_content: }))

    # Replaces the name and the HTML content.
    def update(id, name:, html_content:) = record(patch("/blocks/#{id}", json: { name:, html_content: }))

    def delete(id) = super("/blocks/#{id}")
  end
end
