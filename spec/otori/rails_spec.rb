# frozen_string_literal: true

require "otori/rails"

RSpec.describe Otori::Rails do
  describe Otori::Rails::ControllerMacros do
    let(:controller_base) do
      Class.new do
        class << self
          def before_action_calls = @before_action_calls ||= []

          def before_action(**options, &block)
            before_action_calls << {options: options, block: block}
          end
        end

        extend Otori::Rails::ControllerMacros

        attr_reader :head_status, :head_called

        def head(status)
          @head_called = true
          @head_status = status
        end

        def params
          @params ||= {}
        end

        def session
          @session ||= {}
        end
      end
    end

    it "registers a before_action with the given options" do
      controller_base.honeypot("note", wait: 2, only: :create)

      call = controller_base.before_action_calls.first

      expect(call[:options]).to eq(only: :create)
    end

    it "leaves before_action options empty when no filter is given" do
      controller_base.honeypot("note")

      call = controller_base.before_action_calls.first

      expect(call[:options]).to eq({})
    end

    it "halts with :no_content when the honeypot is filled" do
      controller_base.honeypot("note")
      block = controller_base.before_action_calls.first[:block]
      instance = controller_base.new
      instance.session[Otori.config.session_key("note")] =
        (Otori::Validator.monotonic_ms - 3_000).to_s
      instance.params[:note] = "spam"

      instance.instance_exec(&block)

      expect(instance.head_status).to eq(:no_content)
    end

    it "proceeds silently on a valid submission" do
      controller_base.honeypot("note")
      block = controller_base.before_action_calls.first[:block]
      instance = controller_base.new
      instance.session[Otori.config.session_key("note")] =
        (Otori::Validator.monotonic_ms - 3_000).to_s

      instance.instance_exec(&block)

      expect(instance.head_called).to be_nil
    end

    it "invokes the on_caught block when provided" do
      caught = []
      controller_base.honeypot("note") { caught << :fired }
      block = controller_base.before_action_calls.first[:block]
      instance = controller_base.new
      instance.session[Otori.config.session_key("note")] =
        (Otori::Validator.monotonic_ms - 3_000).to_s
      instance.params[:note] = "spam"

      instance.instance_exec(&block)

      expect(caught).to eq([:fired])
      expect(instance.head_called).to be_nil
    end
  end

  describe Otori::Rails::Helpers do
    let(:view_class) do
      Class.new do
        include Otori::Rails::Helpers
        attr_accessor :session
      end
    end

    let(:view) { view_class.new.tap { |v| v.session = {} } }

    it "renders an invisible honeypot field" do
      html = view.honeypot_field("note")

      expect(html).to include('name="note"')
      expect(html).to include('aria-hidden="true"')
    end

    it "renders a signals hidden input plus tracker script" do
      html = view.honeypot_signals

      expect(html).to include('type="hidden"')
      expect(html).to include("<script>")
    end
  end
end
