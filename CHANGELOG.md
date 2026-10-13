# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-10-13

### Added

- Passing `wait: false` to `Otori.reason` / `Otori.caught?` (and the
  Rails/Hanami `honeypot` macros) skips the timing check entirely while
  keeping the filled-field check active. Useful for forms where
  password-manager autofill or sticky-session returns make even a short
  timer prone to false positives. `wait: nil` continues to fall back to
  `config.default_delay`; only an explicit `false` disables timing.

## [0.4.0] - 2026-10-13

### Added

- `Otori.reason` returns the specific catch reason as a symbol
  (`:filled` when the honeypot field was filled, `:too_fast` when the
  form was submitted before the configured delay elapsed, `nil` when the
  submission looks clean). This lets callers distinguish genuinely
  suspicious submissions from users who merely autofilled and submitted
  faster than the delay allows.
- The Rails adapter's `on_caught` block now receives the reason symbol
  as its sole argument, so applications can log, flag, or branch on it
  (`honeypot(:website) { |reason| ... }`). Zero-arg blocks continue to
  work unchanged.
- The Hanami adapter's `on_caught` block now receives the reason symbol
  as a third argument after `request` and `response`. Two-arg blocks
  continue to work unchanged.

### Changed

- `Otori.caught?` is now a thin predicate over `Otori.reason`. Its
  return value and session side effects are unchanged.

## [0.3.0] - 2026-10-12

### Changed

- `signals_field` now accepts an `id:` attribute. When omitted, a unique id
  of the form `otori-signals-<hex>` is generated per call so multiple
  signals fields can safely coexist on the same page.

### Fixed

- `signals_field` no longer relies on
  `document.currentScript.previousElementSibling` to locate its hidden input.
  The input now carries a unique `id` and the tracking script looks it up via
  `document.getElementById`. The previous approach broke when any DOM mutation
  (Turbo cache restoration, injected elements, browser extensions) landed
  between the input and the script, which could cause the signals JSON to be
  written into a neighbouring field (such as a honeypot) and trigger false
  positives. Callers can supply their own `id:` to override the generated
  value, and the script now bails out silently when the input or its form
  cannot be resolved.

## [0.2.0] - 2026-09-17

### Added

- `Otori::Rails`, an optional adapter for Rails apps. Provides a
  `honeypot` controller class macro that registers a `before_action`
  (halting with `:no_content` by default, or running a user-supplied
  block), and a `honeypot_field` / `honeypot_signals` view-helper pair.
  Loaded via `require "otori/rails"`; auto-hooks via a Railtie when
  present.

## [0.1.0] - 2026-05-22

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
