# frozen_string_literal: true

RSpec.describe RackHoneypot do
  it "has a version number" do
    expect(RackHoneypot::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  describe ".config" do
    it "returns a default configuration" do
      expect(RackHoneypot.config.default_delay).to eq(2.0)
      expect(RackHoneypot.config.disable_delay).to be(false)
      expect(RackHoneypot.config.signals_input_name).to eq("honeypot_signals")
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      RackHoneypot.configure do |c|
        c.default_delay = 5
        c.disable_delay = true
        c.signals_input_name = "signals"
      end

      expect(RackHoneypot.config.default_delay).to eq(5)
      expect(RackHoneypot.config.disable_delay).to be(true)
      expect(RackHoneypot.config.signals_input_name).to eq("signals")
    end
  end

  describe ".field" do
    let(:session) { {} }

    it "renders a hidden input and stores a timestamp in the session" do
      html = RackHoneypot.field("user[website]", session: session)

      expect(html).to include('name="user[website]"')
      expect(html).to include('type="text"')
      expect(html).to include('aria-hidden="true"')
      expect(html).to include('tabindex="-1"')
      expect(html).to include('autocomplete="off"')
      expect(html).to include("position:absolute")

      key = RackHoneypot.config.session_key("user[website]")
      expect(session[key]).to match(/\A\d+\z/)
    end

    it "omits the inline style when a class is given" do
      html = RackHoneypot.field("note", session: session, class: "visually-hidden")
      expect(html).to include('class="visually-hidden"')
      expect(html).not_to include("position:absolute")
    end

    it "omits the inline style when a custom style is given" do
      html = RackHoneypot.field("note", session: session, style: "display:none")
      expect(html).to include('style="display:none"')
      expect(html).not_to include("position:absolute")
    end

    it "escapes attribute values" do
      html = RackHoneypot.field('a"b', session: session)
      expect(html).to include('name="a&quot;b"')
    end

    it "rewrites underscores in attribute names to hyphens" do
      html = RackHoneypot.field("note", session: session, data_purpose: "spam-trap")
      expect(html).to include('data-purpose="spam-trap"')
    end

    it "raises when session is not session-like" do
      expect { RackHoneypot.field("note", session: nil) }
        .to raise_error(RackHoneypot::MissingSession)
    end
  end

  describe ".signals_field" do
    it "renders a hidden input and the tracking script" do
      html = RackHoneypot.signals_field

      expect(html).to include('name="honeypot_signals"')
      expect(html).to include('type="hidden"')
      expect(html).to include("<script>")
      expect(html).to include("addEventListener('mousemove'")
    end

    it "uses the configured input name" do
      RackHoneypot.config.signals_input_name = "signals"
      html = RackHoneypot.signals_field
      expect(html).to include('name="signals"')
    end
  end

  describe ".caught?" do
    let(:session) { {} }
    let(:key) { RackHoneypot.config.session_key("note") }

    context "when the field is empty and the wait has elapsed" do
      before do
        session[key] = (RackHoneypot::Validator.monotonic_ms - 3_000).to_s
      end

      it "returns false and clears the session entry" do
        result = RackHoneypot.caught?("note", params: {"note" => ""}, session: session)
        expect(result).to be(false)
        expect(session).not_to have_key(key)
      end
    end

    context "when the field is filled" do
      before do
        session[key] = (RackHoneypot::Validator.monotonic_ms - 3_000).to_s
      end

      it "returns true and resets the timestamp" do
        result = RackHoneypot.caught?("note", params: {"note" => "spam"}, session: session)
        expect(result).to be(true)
        expect(session[key]).to match(/\A\d+\z/)
      end
    end

    context "when the form was submitted too quickly" do
      before do
        session[key] = RackHoneypot::Validator.monotonic_ms.to_s
      end

      it "returns true" do
        result = RackHoneypot.caught?("note", params: {"note" => ""}, session: session, wait: 5)
        expect(result).to be(true)
      end
    end

    context "when no timestamp was recorded" do
      it "returns true" do
        result = RackHoneypot.caught?("note", params: {"note" => ""}, session: session)
        expect(result).to be(true)
      end
    end

    context "when delays are disabled" do
      before { RackHoneypot.config.disable_delay = true }

      it "passes regardless of session timestamp" do
        result = RackHoneypot.caught?("note", params: {"note" => ""}, session: session)
        expect(result).to be(false)
      end
    end

    it "accepts symbol param keys" do
      session[key] = (RackHoneypot::Validator.monotonic_ms - 3_000).to_s
      result = RackHoneypot.caught?("note", params: {note: ""}, session: session)
      expect(result).to be(false)
    end

    it "digs into bracket-notation params for nested honeypot fields" do
      nested_key = RackHoneypot.config.session_key("user[website]")
      session[nested_key] = (RackHoneypot::Validator.monotonic_ms - 3_000).to_s

      passing = RackHoneypot.caught?(
        "user[website]",
        params: {"user" => {"website" => ""}},
        session: session
      )
      expect(passing).to be(false)

      session[nested_key] = (RackHoneypot::Validator.monotonic_ms - 3_000).to_s
      caught = RackHoneypot.caught?(
        "user[website]",
        params: {"user" => {"website" => "spam"}},
        session: session
      )
      expect(caught).to be(true)
    end
  end

  describe ".signals_rating" do
    it "returns the human rating from JSON" do
      json = '{"m":true,"t":false,"s":true,"k":false,"f":true}'
      expect(RackHoneypot.signals_rating("honeypot_signals" => json)).to eq(0.6)
    end

    it "returns 0.0 when the field is missing" do
      expect(RackHoneypot.signals_rating({})).to eq(0.0)
    end

    it "returns 0.0 when the JSON is invalid" do
      expect(RackHoneypot.signals_rating("honeypot_signals" => "garbage")).to eq(0.0)
    end
  end
end
