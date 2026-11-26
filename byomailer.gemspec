require_relative "lib/byomailer/version"

Gem::Specification.new do |spec|
  spec.name        = "byomailer"
  spec.version     = Byomailer::VERSION
  spec.authors     = [ "Alejandro Medina" ]
  spec.summary     = "Ruby client and Rails integration for the BYOMailer API"
  spec.description = "Manage the contacts, lists, newsletters, sequences and webhooks of a BYOMailer " \
                     "instance, and verify its webhook signatures. The gem uses the Ruby standard library only."
  spec.homepage    = "https://github.com/amedina068/byomailer-ruby"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "https://byomailer.com/docs/sdks/overview",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*", "sig/**/*", "README.md", "CHANGELOG.md", "LICENSE"]
  spec.require_paths = [ "lib" ]
end
