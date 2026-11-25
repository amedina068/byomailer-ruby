# Update report: byomailer-ruby 0.2.0

PR: https://github.com/amedina068/byomailer-ruby/pull/1 (branch `update/0.2.0`, from `origin/main`, not merged)

## Changes

1. `contacts.subscribe(id)` calls `POST /contacts/{id}/subscribe` and returns the contact. A 422 raises `Byomailer::ValidationError`. `errors["contact"]` is set when the contact unsubscribed through an email link. `errors["email"]` is set when the address is blacklisted. The client retries the call like `unsubscribe`, because a second call changes nothing.
2. `contacts.update`: the docblock and the README say that an update never changes the subscription. The README had no caution about an admin unsubscribe, so there was nothing to remove.
3. `contacts.add`: the docblock and the README say that `add` subscribes again a contact that an admin unsubscribed. An unsubscribe that the contact made stays. On an opt-in list, only a contact that is new on the list gets the opt-in email.
4. PUT contact: the gem uses `PATCH`. The README had no note that PUT returns 422, so there was nothing to remove.
5. PATCH `operationId`: the gem does not use operation IDs in code, tests or docs. No change.
6. Sequences: `sequences.list` returns `Byomailer::SequenceSummary` records. `sequences.find` returns a `Byomailer::Sequence`, with `steps`, `filters` and `content_variables`. The RBS type of the `status` filter is `"draft" | "live" | "paused"`. `Page` is generic in RBS (`Page[SequenceSummary]`). The README lists the fields of each type, with `completed_count` and `active_count`.
7. Step mail export: `current_only` is deprecated. The gem does not send it, and gives a Ruby deprecation warning (`category: :deprecated`). The README no longer lists it.
8. Cursor lists: `Page` reads only `data` and `meta.next_cursor`. No change was necessary. The test cursor page now has the `links` and `meta` of a Laravel response.
9. Webhooks: the README says that `newsletter.sent` fires one time, and for an A/B test when you pick the winner. The `pick_winner` docblock and README now say that it sends no more email. The signature vectors did not change, and the webhook tests pass.

Also: the version is `0.2.0`, and `CHANGELOG.md` has a `0.2.0 - Unreleased` section.

## Tests

- `bin/rake test`: 150 runs, 263 assertions, 0 failures (143 before the update)
- `bin/rake test:rails`: 7 runs, 19 assertions, 0 failures
- `bin/rake test:integration`: 3 runs, 3 skips (`BYOMAILER_TEST_URL` and `BYOMAILER_TEST_TOKEN` are not set)
- `bin/rubocop` (lint and format): 50 files, no offenses
- `bin/rake rbs` (type check): valid

## Differences between the spec and the source

- `POST /contacts/{contactId}/subscribe`: the spec lists 200, 401, 403 and 404 only. `ContactSubscribeController` also returns 422 (fields `contact` and `email`). The gem follows the source.
- `POST /newsletters/{id}/ab-winner`: the source now returns 422 with the field `status` when another request picked the winner first. The spec lists 422, but not this case. The gem raises `ValidationError`, as for each 422.
- `current_only`: the spec puts `deprecated: true` in the schema of the parameter, not on the parameter. This does not change the gem.

## Open points

- The `status` type of `sequences.list` exists in RBS only. Ruby does not check the value at runtime. The API returns 422 for another value.
- `SequenceSummary` and `Sequence` read their fields through `Record`, like the other records. The field methods exist in RBS only, not as Ruby methods.
- A Ruby deprecation warning shows only when `Warning[:deprecated]` is true. By default, it is false (Ruby 2.7.2 and later).
- `bin/rake test:integration` did not run against a real instance.
