# Changelog

All notable changes to this project are in this file.

The format is [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-11-25

This release also gives the same behavior as the JS, PHP and Python SDKs.

### Added

- The MIT license: a `LICENSE` file and `spec.license = "MIT"` in the gemspec.
- `Byomailer::Webhook::Event`, the result of `Byomailer::Webhook.verify`.
- The `:payload` reason of `WebhookVerificationError`: the signature is valid, but the body is not a JSON object.
- `retry_after` on each `ApiError`, so a 503 can give it too.

- `contacts.subscribe` clears an unsubscribe that an admin or the API made. It raises `ValidationError` with `errors["contact"]` when the contact unsubscribed through an email link, and with `errors["email"]` when the address is blacklisted.
- `Byomailer::SequenceSummary` for the items of `sequences.list`, and `Byomailer::Sequence` for `sequences.find`. A sequence has `steps`, `filters` and `content_variables`.
- The RBS type of the `status` filter of `sequences.list` is `"draft" | "live" | "paused"`. `Byomailer::Page` has the type of its records.

### Changed

- **Breaking:** `Byomailer::Webhook.verify` returns an `Event` with `type`, `payload`, `timestamp` and `delivery_id`. Before, it returned the payload record. Read the payload from `event.payload`. `delivery_id` is `nil` when the `X-Byomailer-Delivery` header is missing.
- **Breaking:** a missing timestamp header now gives the reason `:timestamp`. Before, it gave `:signature`.
- **Breaking:** `contacts.add(list_id, email, ...)` takes the list ID first, in place of `list:`.
- **Breaking:** `contacts.remove(id, list:)` is now `contacts.remove_from_list(list_id, contact_id)`.
- **Breaking:** the topic methods take the list ID and the topic ID as positional arguments: `topics.list(list_id)`, `topics.create(list_id, name:)`, `topics.update(list_id, topic_id, name:)` and `topics.delete(list_id, topic_id)`.
- **Breaking:** `newsletters.send_test_email` is now `newsletters.send_test`.
- **Breaking:** the client no longer retries `newsletters.update` after a 5xx or a timeout, because `status: "live"` can start the send. A `PATCH` is not idempotent by default now. The operations of the idempotent list pass `idempotent: true`.
- The rule for a connection error before the send did not change: the client retries each request after a DNS failure, a refused connection or a connect timeout. The 12 SDKs of the contract now use this rule.
- The client waits for `Retry-After` on a 5xx too, not only on a 429.
- `Byomailer::Webhook.verify` changes the signature header to lowercase before the compare.
- The README gives the idempotent list and the MIT license.
- The docs say that `contacts.update` never changes the subscription.
- The docs say that `contacts.add` subscribes again a contact that an admin unsubscribed. On an opt-in list, only a contact that is new on the list gets the opt-in email.
- The docs say that `newsletters.pick_winner` sends no more email, and that `newsletter.sent` fires when you pick the winner of an A/B test.

### Deprecated

- The `current_only` filter of `sequences.export_step_mails`. The app ignores it. The gem does not send it, and gives a Ruby deprecation warning.

## [0.1.0] - Not published

Version 0.1.0 was not published. Release 0.2.0 contains these changes.

### Added

- `Byomailer::Client` for one BYOMailer instance, with a bearer token, a timeout and retries.
- `Byomailer.configure`, with fallbacks to `BYOMAILER_URL`, `BYOMAILER_TOKEN` and `BYOMAILER_WEBHOOK_SECRET`.
- Resources for each operation of the API v1: contacts, lists, topics, tags, newsletters, sequences, blocks, email templates, email identities, email logs, projects and webhook endpoints.
- `contacts.add` and `contacts.update` send custom attributes at the top level of the body. `contacts.add` tells a new contact from an existing contact with `created?`.
- `sequences.export_step_mails` returns the CSV text of the mails of a step.
- `Byomailer::Page` for cursor lists, with `next_page` and `each_record`.
- `Byomailer::Webhook.verify` to verify webhook signatures and timestamps, with the test vectors of the app.
- Typed errors for 401, 403, 404, 422, 429, 5xx, connection failures and webhook verification.
- Retries with exponential backoff and jitter. The client obeys `Retry-After`.
- Rails integration: a Railtie that reads the credentials, and the `byomailer:install` generator.
- RBS signatures in `sig/`.
