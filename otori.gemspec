# frozen_string_literal: true

require_relative "lib/otori/version"

Gem::Specification.new do |spec|
  spec.name = "otori"
  spec.version = Otori::VERSION
  spec.authors = ["Wout"]
  spec.email = ["hi@wout.codes"]

  spec.summary = "Invisible honeypot spam protection for Rack apps, with a Hanami adapter."
  spec.description = <<~DESC
    Drop-in honeypot spam protection for any Rack-based app. Combines an
    invisible form field, a submission-timing check, and a JavaScript input
    signals tracker (mouse, touch, scroll, keyboard, focus) into a single
    framework-agnostic gem, with an opt-in Hanami adapter. Ruby companion to
    the Crystal lucky_honeypot shard.
  DESC
  spec.homepage = "https://codeberg.org/fluck/otori"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/src/branch/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "CHANGELOG.md",
    "LICENSE"
  ]
  spec.require_paths = ["lib"]
end
