module Byomailer
  # Only an admin can manage webhook endpoints. Other users get AuthorizationError.
  class WebhookEndpoints < Resource
    def list(per_page: nil, cursor: nil) = page("/webhook-endpoints", per_page:, cursor:)

    # The endpoint without its secret.
    def find(id) = record(get("/webhook-endpoints/#{id}"))

    # The response has the secret. Keep it: the API shows it again only after rotate_secret.
    #
    #   endpoint = Byomailer.webhook_endpoints.create(url: "https://example.com/webhooks", events: %w[contact.subscribed])
    #   endpoint.secret
    def create(url:, events:, description: nil)
      record(post("/webhook-endpoints", json: { url:, events:, description: }.compact))
    end

    # Changes the description, or turns the endpoint on or off with active.
    def update(id, **attributes) = record(patch("/webhook-endpoints/#{id}", json: attributes, idempotent: true))

    def delete(id) = super("/webhook-endpoints/#{id}")

    # A page of deliveries, newest first.
    def deliveries(id, per_page: nil, cursor: nil)
      page("/webhook-endpoints/#{id}/deliveries", per_page:, cursor:)
    end

    # Makes a new secret and returns the endpoint with it. The old secret stops at once.
    def rotate_secret(id) = record(post("/webhook-endpoints/#{id}/secret"))

    # Queues a webhook.test delivery and returns it. The limit is 10 requests a minute.
    def send_test(id) = record(post("/webhook-endpoints/#{id}/test"))
  end
end
