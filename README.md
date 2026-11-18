# BYOMailer for Ruby

A Ruby client for the BYOMailer API, with a Rails integration.

BYOMailer is a self-hosted app that sends newsletters and email sequences through your Amazon SES account. You run your own BYOMailer instance, so each client talks to the instance URL that you give it. The gem uses the Ruby standard library only. It has no runtime dependencies and sends no telemetry.

```ruby
contact = Byomailer.contacts.add("ana@example.com", list: 3, name: "Ana", attributes: { company: "Acme" })
event = Byomailer::Webhook.verify(request.raw_post, request.headers)
```

## Install

Add the gem to your Gemfile:

```ruby
gem "byomailer", github: "amedina068/byomailer-ruby"
```

Then run `bundle install`.

The gem is not on RubyGems yet.

## Quick start

1. In your BYOMailer instance, go to Settings, API Tokens. Make a token.
2. Configure the client:

   ```ruby
   require "byomailer"

   Byomailer.configure do |config|
     config.url   = "https://mail.example.com"
     config.token = ENV["BYOMAILER_TOKEN"]
   end
   ```

3. Add a contact to a list:

   ```ruby
   list = Byomailer.lists.list.first
   contact = Byomailer.contacts.add("ana@example.com", list: list.id, tags: ["vip"])
   contact.created?   # => true when the email was new
   ```

## Configuration

| Setting          | Default | Environment variable       | Description |
|------------------|---------|----------------------------|-------------|
| `url`            | none    | `BYOMAILER_URL`            | The URL of your instance, for example `https://mail.example.com`. The client adds `/api/v1`. |
| `token`          | none    | `BYOMAILER_TOKEN`          | The API token. The client sends it as `Authorization: Bearer`. |
| `webhook_secret` | none    | `BYOMAILER_WEBHOOK_SECRET` | The secret of your webhook endpoint. Only `Byomailer::Webhook.verify` uses it. |
| `timeout`        | `30`    |                            | The seconds to wait for a connection and for a response. |
| `max_retries`    | `2`     |                            | The retries after a failed request. `0` turns retries off. |

`Byomailer.contacts` and the other module methods use the default client. To talk to more than one instance, make a client for each one:

```ruby
client = Byomailer::Client.new(url: "https://mail.example.com", token: ENV["BYOMAILER_TOKEN"], timeout: 10)
client.tags.list
```

A token has read access, or read and write access. A read-only token gets `Byomailer::AuthorizationError` on each request that changes data. Each request sees only the data of the client of the token user.

## Usage

Each method returns a `Byomailer::Record`, an Array of records, or a `Byomailer::Page`. Read a field as a method or with `[]`:

```ruby
contact = Byomailer.contacts.find(42)
contact.email          # => "ana@example.com"
contact[:email]        # => "ana@example.com"
contact.to_h           # => { "id" => 42, "email" => "ana@example.com", ... }
contact.key?(:phone)   # => false
```

A field that the record does not have raises `NoMethodError` as a method, and gives `nil` with `[]`.

To call a route that the gem does not wrap yet, use `request`. It returns the status and the parsed body, with the same errors and retries:

```ruby
response = Byomailer.client.request(:get, "/tags")
response.status   # => 200
response.body     # => { "data" => [...] }
```

### Contacts

A key of `attributes` becomes a custom attribute of the contact. The gem sends each key at the top level of the body, as the API expects.

```ruby
Byomailer.contacts.list(lists: [3], tags: [4], topics: [9], search: "ana", include_unsubscribed: true)
Byomailer.contacts.find(42)
Byomailer.contacts.add("ana@example.com", list: 3, name: "Ana", tags: ["vip"], attributes: { plan: "pro" })
Byomailer.contacts.update(42, name: "Ana P.", remove_tags: ["trial"], attributes: { plan: "team" })
Byomailer.contacts.unsubscribe(42)
Byomailer.contacts.remove(42, list: 3)
```

`add` returns a `Byomailer::Contacts::Added`. `created?` is `true` when the API made a new contact (HTTP 201), and `false` when it updated an existing contact (HTTP 200).

`update` sends only the fields that you give. `tags` adds tags, and `remove_tags` removes tags. To clear the name, send `name: ""`.

### Lists, topics and tags

```ruby
Byomailer.lists.list
Byomailer.lists.create(name: "Customers")
Byomailer.lists.rename(3, name: "Buyers")
Byomailer.lists.delete(3)

Byomailer.topics.list(list: 3)
Byomailer.topics.create(list: 3, name: "Product news", description: "Launches and updates")
Byomailer.topics.update(7, list: 3, name: "Launches", description: "New products")
Byomailer.topics.delete(7, list: 3)

Byomailer.tags.list
Byomailer.tags.create(name: "VIP")
Byomailer.tags.rename(4, name: "Gold")
Byomailer.tags.delete(4)
```

`topics.update` replaces the name and the description. If you do not give a description, the topic has no description after the update.

`tags.list`, `topics.list` and `blocks.list` return all the items in one Array. These lists have no pages.

### Newsletters

```ruby
Byomailer.newsletters.list(status: "sent", project: 2, search: "November")
Byomailer.newsletters.find(7)
Byomailer.newsletters.create(title: "November news", subject: "News", html_content: "<p>Hello {{ first_name }}</p>")
Byomailer.newsletters.update(7, status: "live", scheduled_at: "2026-12-01T09:00:00Z", email_identity_id: 1)
Byomailer.newsletters.delete(7)
Byomailer.newsletters.count_recipients(filters: [{ category: "tags", mode: "any", values: [4] }])   # => 128
Byomailer.newsletters.send_test_email(7)
Byomailer.newsletters.pick_winner(7, "b")
Byomailer.newsletters.variables(7)
Byomailer.newsletters.replace_variables(7, first_name: "friend")
```

`create` and `update` send the attributes as they are. The API reads `title`, `subject`, `preview_text`, `html_content`, `status`, `scheduled_at`, `email_identity_id`, `email_template_id`, `ab_test_enabled`, `subject_b`, `preview_text_b`, `html_content_b`, `content_variables`, `filters` and `project_ids`.

CAUTION: `status: "live"` schedules a real send. A `scheduled_at` in the past or now queues the send at once.

`delete` deletes a draft only. A newsletter with another status raises `Byomailer::ValidationError`.

`send_test_email` sends the newsletter to the email address of the token user. `pick_winner` sends variant `"a"` or `"b"` to the rest of the audience of an A/B test.

### Sequences

```ruby
Byomailer.sequences.list(status: "live")
Byomailer.sequences.find(3)
Byomailer.sequences.stats(3)
Byomailer.sequences.step(3, 11)
Byomailer.sequences.step_stats(3, 11)
Byomailer.sequences.replace_step_filters(3, 11, [{ category: "tags", mode: "none", values: [5] }])
Byomailer.sequences.variables(3)
Byomailer.sequences.replace_variables(3, plan: "free")
```

`export_step_mails` returns the CSV text of the mails of one step. The keyword arguments filter the rows:

```ruby
csv = Byomailer.sequences.export_step_mails(3, 11, status: "bounced", sent_after: Time.utc(2026, 11, 1))
File.write("bounced.csv", csv)
```

The filters are `contact_id`, `status`, `filter`, `search`, `sent_after`, `sent_before`, `sort`, `direction` and `current_only`.

### Blocks and email templates

```ruby
Byomailer.blocks.list
Byomailer.blocks.find(5)
Byomailer.blocks.create(name: "footer", html_content: "<p>See you soon</p>")
Byomailer.blocks.update(5, name: "footer", html_content: "<p>Bye</p>")
Byomailer.blocks.delete(5)

Byomailer.email_templates.list(archived: false)
Byomailer.email_templates.find(2)
Byomailer.email_templates.default
```

`email_templates.default` raises `Byomailer::NotFoundError` when no template is the default.

### Email identities, email logs and projects

```ruby
Byomailer.email_identities.list(identity_status: "verified")
Byomailer.email_identities.find(1)

Byomailer.email_logs.list(status: "bounced", operation: "send", recipient: "example.com")
Byomailer.email_logs.find(9)

Byomailer.projects.list
Byomailer.projects.find(2)
Byomailer.projects.create(name: "Launch")
Byomailer.projects.rename(2, name: "Relaunch")
Byomailer.projects.delete(2)
```

### Webhook endpoints

Only an admin can manage webhook endpoints. A token of a user who is not an admin gets `Byomailer::AuthorizationError`.

```ruby
endpoint = Byomailer.webhook_endpoints.create(url: "https://example.com/webhooks/byomailer", events: %w[contact.subscribed newsletter.sent])
endpoint.secret   # keep it: the API shows it only now and after rotate_secret

Byomailer.webhook_endpoints.list
Byomailer.webhook_endpoints.find(5)
Byomailer.webhook_endpoints.update(5, active: false, description: "Paused")
Byomailer.webhook_endpoints.deliveries(5, per_page: 50)
Byomailer.webhook_endpoints.rotate_secret(5).secret
Byomailer.webhook_endpoints.send_test(5)
Byomailer.webhook_endpoints.delete(5)
```

## Pagination

The list methods of contacts, lists, newsletters, sequences, email templates, email identities, email logs, projects, webhook endpoints and deliveries return a `Byomailer::Page`. A page has up to `per_page` records (1 to 100, default 25).

```ruby
page = Byomailer.contacts.list(per_page: 100)
page.each { |contact| puts contact.email }
page.next_cursor     # => "eyJpZCI6..." or nil
page = page.next_page if page.next_page?
```

`each_record` walks every page. It sends the next request only when it needs the next page:

```ruby
Byomailer.contacts.list(tags: [4], per_page: 100).each_record do |contact|
  puts contact.email
end

Byomailer.contacts.list.each_record.first(10)
```

To start at a cursor that you saved, give `cursor:` to `list`.

## Webhook verification

BYOMailer signs each webhook delivery. `Byomailer::Webhook.verify` verifies the signature and the timestamp, and returns the decoded payload.

Verify webhooks on the server only. The endpoint secret is a secret. Never put it in browser code.

```ruby
class ByomailerWebhooksController < ActionController::API
  def create
    event = Byomailer::Webhook.verify(request.raw_post, request.headers)

    case event.event
    when "contact.subscribed"   then Subscriber.welcome(event.contact.email)
    when "contact.unsubscribed" then Subscriber.goodbye(event.contact.email)
    end

    head :ok
  rescue Byomailer::WebhookVerificationError
    head :bad_request
  end
end
```

- Give the raw body, byte for byte. Do not parse the JSON and encode it again. BYOMailer escapes Unicode as `\uXXXX` and does not escape `/`, so a new encoding gives other bytes.
- `headers` can be the Rails `request.headers`, a Rack env, or a Hash.
- The secret comes from `config.webhook_secret`. To give it directly, pass `secret: "whsec_..."`.
- The timestamp must be 300 seconds or less before or after the current time. To change this limit, pass `tolerance: 600`.
- Each problem raises `Byomailer::WebhookVerificationError`. Its `reason` is `:signature` or `:timestamp`.

To test your own webhook controller, sign a body with `Byomailer::Webhook.sign`:

```ruby
body = %({"event":"webhook.test","occurred_at":"2026-11-18T10:00:00+00:00"})
timestamp = Time.now.to_i.to_s

post "/webhooks/byomailer", params: body, headers: {
  "Content-Type" => "application/json",
  "X-Byomailer-Timestamp" => timestamp,
  "X-Byomailer-Signature" => Byomailer::Webhook.sign(timestamp, body, "whsec_test")
}
```

The events are `contact.subscribed`, `contact.unsubscribed`, `contact.resubscribed`, `newsletter.sent`, `sequence_step.sent`, `sequence.completed` and `webhook.test`. Each payload has `event` and `occurred_at`. The app can add events, so `verify` accepts other event names too. `Byomailer::Webhook::EVENTS` lists the known events.

## Errors

Each error is a `Byomailer::Error`.

| Error | When |
|-------|------|
| `Byomailer::ConfigurationError` | The url, the token or the webhook secret is missing. |
| `Byomailer::ConnectionError` | The request got no response: the connection failed or timed out. |
| `Byomailer::AuthenticationError` | HTTP 401. The token is missing, wrong or revoked. |
| `Byomailer::AuthorizationError` | HTTP 403. The token is read-only, or the user is not an admin. |
| `Byomailer::NotFoundError` | HTTP 404. |
| `Byomailer::ValidationError` | HTTP 422. `errors` has the messages for each field. |
| `Byomailer::RateLimitError` | HTTP 429. `retry_after` has the seconds to wait. |
| `Byomailer::ServerError` | HTTP 500 or more. |
| `Byomailer::ApiError` | Another status. All the errors with a status are an `ApiError`. |
| `Byomailer::WebhookVerificationError` | A webhook delivery is not valid. `reason` is `:signature` or `:timestamp`. |

Each `ApiError` has `status`, `body` and the `message` from the body.

```ruby
begin
  Byomailer.contacts.add("not-an-email", list: 3)
rescue Byomailer::ValidationError => error
  error.errors   # => { "email" => ["The email field must be a valid email address."] }
end
```

## Retries

The client retries these failures, up to `max_retries` times:

- HTTP 429, for each request. The client waits for the `Retry-After` value. If `Retry-After` is more than 60 seconds, the client does not retry and raises `RateLimitError`.
- A connection error before the request reached the server, for each request.
- HTTP 5xx and a timeout after the request was sent, for an idempotent request only.

`GET`, `PATCH` and `DELETE` requests are idempotent. A `POST` is not, so the client does not send it again after a 5xx. Two `POST` requests are exceptions: `contacts.unsubscribe` and `newsletters.count_recipients` change nothing on a second call.

The wait before each retry grows: 0.5, 1, 2, 4 and 8 seconds at most. The client adds random jitter, and waits between half and all of each value.

Three endpoints have a rate limit:

| Method | Limit |
|--------|-------|
| `newsletters.count_recipients` | 30 requests a minute for each user |
| `newsletters.send_test_email` | 5 requests a minute for each user |
| `webhook_endpoints.send_test` | 10 requests a minute for each client |

## Rails

The gem has a Railtie and an install generator. Rails loads them when the gem loads.

### Credentials

The Railtie reads `Rails.application.credentials.byomailer`:

```sh
bin/rails credentials:edit
```

```yaml
byomailer:
  url: https://mail.example.com
  token: your-api-token
  webhook_secret: your-webhook-secret
```

An initializer that calls `Byomailer.configure` runs after the Railtie. Its values win.

### Generator

```sh
bin/rails generate byomailer:install
```

The generator writes `config/initializers/byomailer.rb` with the settings and their defaults.

### Webhooks in a controller

Use the controller in [Webhook verification](#webhook-verification). Use `ActionController::API`, or skip the CSRF check for the webhook action. Add a route:

```ruby
post "/webhooks/byomailer", to: "byomailer_webhooks#create"
```

## Supported versions

- Ruby 3.2, 3.3 and 3.4
- Rails 7.2, 8.0 and 8.1 for the Rails integration. The client works without Rails.
- BYOMailer API v1

## Development

Read [CONTRIBUTING.md](CONTRIBUTING.md).

```sh
bundle install
bin/rake           # unit, Rails and integration tests
bin/rubocop
bin/rake rbs       # validate the RBS signatures in sig/
```
