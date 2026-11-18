# Contributing

Thank you for your help with the BYOMailer Ruby gem.

## Report a bug or ask for a feature

Open an issue with the bug template or the feature template. If the problem is about security, do not open an issue. Read [SECURITY.md](SECURITY.md).

## Prepare your environment

1. Install Ruby 3.2 or later.
2. Clone the repository.
3. Run `bundle install`.
4. Run `bin/rake`. All tests must pass before you change the code.

## Make a change

1. Make a branch from `main`.
2. Write a test that shows the bug or the new behavior. Make sure that the test fails.
3. Change the code until the test passes.
4. Run `bin/rake`, `bin/rubocop` and `bin/rake rbs`.
5. If you change the public API, update `sig/byomailer.rbs`, `README.md` and `CHANGELOG.md`.
6. Open a pull request and complete the template.

## Rules for the code

- Use the Ruby standard library. Do not add a runtime dependency.
- Use Minitest for the tests. Do not make real HTTP requests in the unit tests. Use WebMock.
- Follow the RuboCop rules of `rubocop-rails-omakase`.
- Do not add telemetry.
- Never put a token, a webhook secret or another secret in the code, the tests or the logs. Use `example.com` data.

## Rules for the text

Write the docs, the comments and the commit messages in Simplified Technical English:

- Use short sentences. A procedure step has 20 words or fewer. A description has 25 words or fewer.
- Use the active voice. Use the imperative for instructions.
- Use one word for one meaning.
- Do not use contractions or semicolons.

## Update the webhook test vectors

The file `test/fixtures/webhook-signature-vectors.json` comes from the BYOMailer app. If the app changes the signature, get the new file from the app and run `bin/rake test`.

## Test with a different Rails version

Set `RAILS_VERSION` and update the bundle:

```sh
RAILS_VERSION="~> 7.2.0" bundle update rails
bin/rake test:rails
```

## Run the integration tests

The integration tests use a real BYOMailer instance. They only read: they list contacts, lists and tags. They never send email.

```sh
BYOMAILER_TEST_URL=https://mail.example.com BYOMAILER_TEST_TOKEN=your-token bin/rake test:integration
```

A read-only token is enough for these tests.
