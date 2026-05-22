# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial scaffolding inspired by the
  [Crystal lucky_honeypot shard](https://codeberg.org/fluck/lucky_honeypot).
- `RackHoneypot::Configuration` with `default_delay`, `disable_delay`, and
  `signals_input_name`, accessed via `RackHoneypot.configure`.
- `RackHoneypot::Form.field` and `RackHoneypot::Form.signals_field` for
  rendering the invisible honeypot input and the input-signals tracker as
  framework-agnostic HTML strings.
- `RackHoneypot::Signals` for parsing the JSON payload submitted by the
  tracker and computing a `human_rating` between 0 and 1.
- `RackHoneypot::Validator` with `filled?` and `elapsed?` for the two
  core form checks.
- `RackHoneypot.caught?` combining the field and timing checks against a
  session and params hash, with timestamp cleanup on success and reset on
  failure.
- `RackHoneypot.signals_rating` convenience for computing the human rating
  straight from a params hash.
- `RackHoneypot::Hanami::Action`, an optional adapter providing a
  `honeypot` class macro that registers a Hanami `before` callback,
  halting with 204 by default or running a user-supplied block.
- `RackHoneypot::Hanami::Helpers`, an optional view-helper module exposing
  `honeypot_field` and `honeypot_signals` for Hanami views.
- `RackHoneypot::Error` and `RackHoneypot::MissingSession` exception
  types.
- Codeberg / Forgejo CI workflow running rspec and rubocop on Ruby 3.4
  and 4.0.
- README covering quickstart, framework integration for Hanami, Rails,
  and any Rack app, configuration, signals interpretation, and security
  considerations.
