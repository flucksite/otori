# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial scaffolding inspired by the
  [Crystal lucky_honeypot shard](https://codeberg.org/fluck/lucky_honeypot).
- `Otori::Configuration` with `default_delay`, `disable_delay`, and
  `signals_input_name`, accessed via `Otori.configure`.
- `Otori::Form.field` and `Otori::Form.signals_field` for
  rendering the invisible honeypot input and the input-signals tracker as
  framework-agnostic HTML strings.
- `Otori::Signals` for parsing the JSON payload submitted by the
  tracker and computing a `human_rating` between 0 and 1.
- `Otori::Validator` with `filled?` and `elapsed?` for the two
  core form checks.
- `Otori.caught?` combining the field and timing checks against a
  session and params hash, with timestamp cleanup on success and reset on
  failure.
- `Otori.signals_rating` convenience for computing the human rating
  straight from a params hash.
- `Otori::Hanami::Action`, an optional adapter providing a
  `honeypot` class DSL method that registers a Hanami `before` callback,
  halting with 204 by default or running a user-supplied block.
- `Otori::Hanami::Helpers`, an optional view-helper module exposing
  `honeypot_field` and `honeypot_signals` for Hanami views.
- `Otori::Error` and `Otori::MissingSession` exception
  types.
- Codeberg / Forgejo CI workflow running rspec and rubocop on Ruby 3.4
  and 4.0.
- README covering quickstart, framework integration for Hanami, Rails,
  and any Rack app, configuration, signals interpretation, and security
  considerations.
