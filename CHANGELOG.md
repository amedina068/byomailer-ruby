# Changelog

All notable changes to this project are in this file.

The format is [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - Unreleased

### Added

- `contacts.subscribe` clears an unsubscribe that an admin or the API made. It raises `ValidationError` with `errors["contact"]` when the contact unsubscribed through an email link, and with `errors["email"]` when the address is blacklisted.
- `Byomailer::SequenceSummary` for the items of `sequences.list`, and `Byomailer::Sequence` for `sequences.find`. A sequence has `steps`, `filters` and `content_variables`.
- The RBS type of the `status` filter of `sequences.list` is `"draft" | "live" | "paused"`. `Byomailer::Page` has the type of its records.

### Changed

- The docs say that `contacts.update` never changes the subscription.
- The docs say that `contacts.add` subscribes again a contact that an admin unsubscribed. On an opt-in list, only a contact that is new on the list gets the opt-in email.
- The docs say that `newsletters.pick_winner` sends no more email, and that `newsletter.sent` fires when you pick the winner of an A/B test.

### Deprecated

- The `current_only` filter of `sequences.export_step_mails`. The app ignores it. The gem does not send it, and gives a Ruby deprecation warning.

## [0.1.0] - Unreleased

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
