# frozen_string_literal: true

require "rack_honeypot/hanami"

RSpec.describe RackHoneypot::Hanami do
  describe RackHoneypot::Hanami::Action do
    let(:action_base) do
      Class.new do
        class << self
          def before_callbacks
            @before_callbacks ||= []
          end

          def before(&block)
            before_callbacks << block
          end
        end

        attr_reader :halted_with

        def halt(status)
          @halted_with = status
          throw :halt, status
        end

        def call(request, response)
          catch :halt do
            self.class.before_callbacks.each do |callback|
              instance_exec(request, response, &callback)
            end
            :proceeded
          end
        end
      end
    end

    let(:request) { double("Request", params: params, session: session) }
    let(:response) { double("Response") }
    let(:session) { {} }
    let(:params) { {} }

    it "halts with 204 when the field is filled" do
      action_class = Class.new(action_base) { include RackHoneypot::Hanami::Action }
      action_class.honeypot("note")

      session[RackHoneypot.config.session_key("note")] =
        (RackHoneypot::Validator.monotonic_ms - 3_000).to_s
      params["note"] = "spam"

      action = action_class.new
      result = action.call(request, response)

      expect(action.halted_with).to eq(204)
      expect(result).to eq(204)
    end

    it "proceeds when the form is valid" do
      action_class = Class.new(action_base) { include RackHoneypot::Hanami::Action }
      action_class.honeypot("note")

      session[RackHoneypot.config.session_key("note")] =
        (RackHoneypot::Validator.monotonic_ms - 3_000).to_s

      action = action_class.new
      result = action.call(request, response)

      expect(action.halted_with).to be_nil
      expect(result).to eq(:proceeded)
    end

    it "invokes the supplied block when caught" do
      called_with = nil
      action_class = Class.new(action_base) { include RackHoneypot::Hanami::Action }
      action_class.honeypot("note") do |req, _res|
        called_with = req
        halt 303
      end

      params["note"] = "spam"
      action = action_class.new
      action.call(request, response)

      expect(called_with).to eq(request)
      expect(action.halted_with).to eq(303)
    end

    it "honors a custom wait" do
      action_class = Class.new(action_base) { include RackHoneypot::Hanami::Action }
      action_class.honeypot("note", wait: 10)

      session[RackHoneypot.config.session_key("note")] =
        (RackHoneypot::Validator.monotonic_ms - 3_000).to_s

      action = action_class.new
      action.call(request, response)

      expect(action.halted_with).to eq(204)
    end
  end

  describe RackHoneypot::Hanami::Helpers do
    let(:view_class) do
      Class.new do
        include RackHoneypot::Hanami::Helpers

        attr_reader :request

        def initialize(request)
          @request = request
        end
      end
    end

    it "renders the honeypot field using the request session" do
      session = {}
      request = double("Request", session: session)
      view = view_class.new(request)

      html = view.honeypot_field("note")

      expect(html).to include('name="note"')
      expect(session[RackHoneypot.config.session_key("note")]).to match(/\A\d+\z/)
    end

    it "renders the signals field" do
      view = view_class.new(double("Request", session: {}))
      expect(view.honeypot_signals).to include('name="honeypot_signals"')
    end
  end
end
