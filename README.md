# RackHoneypot

[![CI](https://codeberg.org/fluck/rack_honeypot/actions/workflows/ci.yml/badge.svg)](https://codeberg.org/fluck/rack_honeypot/actions?workflow=ci.yml)
[![Version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fcodeberg.org%2Fapi%2Fv1%2Frepos%2Ffluck%2Frack_honeypot%2Ftags&query=%24%5B0%5D.name&label=version)](https://codeberg.org/fluck/rack_honeypot/tags)

Invisible captcha spam protection for any Rack-based Ruby app, with an opt-in
Hanami adapter.

This is a Ruby companion to the [Crystal lucky_honeypot
shard](https://codeberg.org/fluck/lucky_honeypot). It combines three classic
techniques into one gem:

1. **Invisible fields**. Bots fill out every field, including ones hidden with CSS.
2. **Timing checks**. Bots submit forms instantly, humans need more time.
3. **Input signals**. Bots don't tend to trigger mouse, touch, scroll, keyboard, or focus events.

When either of the first two checks fail, the submission is quietly rejected.
The bot thinks it succeeded and moves on. The third one can be used to reject
or flag submissions at a chosen _human rating_ threshold.

> [!NOTE]
> The original repository is hosted at
> [Codeberg](https://codeberg.org/fluck/rack_honeypot). The [GitHub
> repo](https://github.com/flucksite/rack_honeypot) is just a mirror.

## Installation

Add this to your Gemfile:

```ruby
gem "rack_honeypot"
```

Then run `bundle install`. Ruby 3.2 or newer is required.

## Quickstart

The gem ships a framework-agnostic core plus an opt-in Hanami adapter. The core
API is three calls:

```ruby
RackHoneypot.field("user[website]", session: request.session)
RackHoneypot.signals_field
RackHoneypot.caught?("user[website]", params: request.params, session: request.session)
```

`field` renders the invisible input and stores a load timestamp in the
session. `signals_field` renders a hidden input plus the JavaScript that
tracks human input. `caught?` checks the submitted form and returns `true`
when the request looks like a bot.

Field names use standard HTML bracket notation, so `"user[website]"` lives
under `params[:user][:website]` once submitted. Flat names like `"note"` work
too. Pick whichever fits the surrounding form, the more believable the
honeypot looks next to the real fields, the better.

## Framework integration

### Hanami

The Hanami adapter is loaded explicitly so the base gem stays dependency-free:

```ruby
require "rack_honeypot/hanami"
```

Mix the helpers into your views:

```ruby
# app/views/helpers.rb
module MyApp
  module Views
    module Helpers
      include RackHoneypot::Hanami::Helpers
    end
  end
end
```

In a form template:

```erb
<%= honeypot_field("user[website]") %>
<%= honeypot_signals %>
```

The helpers mark their output safe via `String#html_safe`, which Hanami View
provides out of the box, so the HTML flows through ERB without escaping.

Guard the receiving action with the `honeypot` DSL method:

```ruby
# app/actions/sign_ups/create.rb
module MyApp
  module Actions
    module SignUps
      class Create < MyApp::Action
        include RackHoneypot::Hanami::Action

        honeypot "user[website]"

        def handle(request, response)
          # ...
        end
      end
    end
  end
end
```

When the honeypot is tripped, the action halts with `204 No Content` by
default. To customize the response, pass a block:

```ruby
honeypot "user[website]" do |_request, response|
  response.flash[:info] = "Moving on..."
  response.redirect_to "/", status: 303
end
```

Multiple honeypots are supported, each with its own timing and handler:

```ruby
honeypot "user[website]", wait: 5
honeypot "note" do |_req, _res|
  halt 422
end
```

To act on the input-signals rating, evaluate it inside `handle`:

```ruby
def handle(request, response)
  rating = RackHoneypot.signals_rating(request.params.to_h)
  halt 204 if rating < 0.4

  # ...
end
```

### Rack (Sinatra, Roda, plain Rack)

There is no adapter to require, the core API is enough. In a Sinatra app:

```ruby
require "rack_honeypot"

enable :sessions

get "/sign_up" do
  erb :sign_up
end

post "/sign_up" do
  halt 204 if RackHoneypot.caught?(
    "user[website]",
    params: params,
    session: session
  )

  # ...
end
```

In the view:

```erb
<%= RackHoneypot.field("user[website]", session: session) %>
<%= RackHoneypot.signals_field %>
```

### Rails

Rails is well served by [invisible_captcha](https://github.com/markets/invisible_captcha)
when all you need is a hidden field and a timing check. Use this gem in Rails
if you want the input-signals rating on top.

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def honeypot_field(name, **attrs)
    RackHoneypot.field(name, session: session, **attrs).html_safe
  end

  def honeypot_signals(**attrs)
    RackHoneypot.signals_field(**attrs).html_safe
  end
end
```

```ruby
# app/controllers/sign_ups_controller.rb
class SignUpsController < ApplicationController
  before_action :check_honeypot, only: :create

  def create
    # ...
  end

  private

  def check_honeypot
    return unless RackHoneypot.caught?(
      "user[website]",
      params: params.to_unsafe_h,
      session: session
    )

    head :no_content
  end
end
```

## Configuration

```ruby
RackHoneypot.configure do |c|
  # Required delay (in seconds) between page load and form submission.
  c.default_delay = 2.0

  # Disables the submission delay entirely. Useful in tests.
  c.disable_delay = false

  # Name of the hidden input that carries the signals payload.
  c.signals_input_name = "honeypot_signals"
end
```

## The invisible field

By default the field is rendered with an inline `style` attribute that takes
it out of the visual flow without breaking accessibility tools. Pass your own
`class` (or `style`) to opt out of the default style and use your CSS instead:

```ruby
RackHoneypot.field("user[website]", session: session, class: "visually-hidden")
```

Underscored attribute keys are converted to dashes so `data_foo: "bar"`
renders as `data-foo="bar"`. Any other attribute pair is passed through
unchanged.

> [!NOTE]
> The field stores a load timestamp in the session under a
> `honeypot_field_<name>` key. The companion `caught?` call reads and
> clears it on success, or resets it when the form is rejected.

## Detecting input signals

`signals_field` renders a hidden input plus a small inline `<script>` that
listens for the first occurrence of each of five events on the surrounding
form: `mousemove`, `touchstart`, `keydown`, `focusin`, and a window-level
`scroll`. On submit, the boolean results are serialized to JSON and posted
along with the rest of the form.

In the action, get the rating directly from the params:

```ruby
RackHoneypot.signals_rating(params)        # => 0.0 to 1.0
```

Or work with the parsed object for more detail:

```ruby
signals = RackHoneypot::Signals.from_json(params["honeypot_signals"])
signals.human_rating  # 0 (bot) to 1 (human)
signals.mouse?
signals.touch?
signals.scroll?
signals.keyboard?
signals.focus?
```

> [!NOTE]
> The human rating is the fraction of the five signals that fired, so each one
> contributes `0.2`. A score of `0` is almost certainly a dumb bot, while `0.2`
> could be a sophisticated bot triggering a single signal (almost always
> `mouse`), though a human filling out a short form at the top of the page may
> also land there.
>
> `0.4` is a reasonable threshold for flagging entries: it still catches bots
> that fake one or two signals, but avoids false positives for autofill and
> password manager submissions, which often only trigger focus plus mouse or
> touch.

## Security considerations

This gem provides basic bot protection, but it should not be your only line
of defense.

- It is not foolproof, sophisticated bots can bypass honeypots.
- Combine this with a rate limiter such as `rack-attack`.
- For high-value forms, consider adding CAPTCHA or email verification.
- The submission timestamp is stored in the session. If sessions are
  compromised, an attacker could manipulate timing checks. Make sure your session
  store uses signed and encrypted cookies.
- The timing check compares wall-clock timestamps, which makes it resilient to
  timing attacks since the check is a simple threshold comparison.
- This gem does not touch CSRF tokens. Honeypot fields are regular form inputs
  and do not interfere with your framework's CSRF protection.

For most use cases (contact forms, newsletter signups), this gem provides solid
protection with zero user friction. Expect it to catch between 60% and 90% of
automated form submissions.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
