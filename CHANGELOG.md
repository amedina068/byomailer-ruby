# Changelog

All notable changes to this project are in this file.

The format is [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
