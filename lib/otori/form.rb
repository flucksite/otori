# frozen_string_literal: true

require "cgi"

require_relative "validator"

module Otori
  module Form
    extend self

    HIDDEN_STYLE = "position:absolute;left:-9999px;width:1px;height:1px;pointer-events:none;"

    SIGNALS_SCRIPT = <<~JS
      (() => {
        const s = { m: false, t: false, s: false, k: false, f: false };
        const input = document.currentScript.previousElementSibling;
        const form = input.form;
        form.addEventListener('mousemove', () => s.m = true, { once: true });
        form.addEventListener('touchstart', () => s.t = true, { once: true });
        form.addEventListener('keydown', () => s.k = true, { once: true });
        form.addEventListener('focusin', () => s.f = true, { once: true });
        window.addEventListener('scroll', () => s.s = true, { once: true });
        form.addEventListener('submit', () => input.value = JSON.stringify(s));
      })();
    JS

    def field(name, session:, **attrs)
      raise MissingSession unless session_like?(session)

      session[Otori.config.session_key(name)] = Validator.monotonic_ms.to_s

      base = {
        name: name.to_s,
        type: "text",
        "aria-hidden": "true",
        tabindex: "-1",
        autocomplete: "off"
      }
      base[:style] = HIDDEN_STYLE unless attrs.key?(:class) || attrs.key?(:style)

      tag(:input, base.merge(stringify_keys(attrs)))
    end

    def signals_field(**attrs)
      input = tag(:input, {
        name: Otori.config.signals_input_name,
        type: "hidden"
      }.merge(stringify_keys(attrs)))

      "#{input}<script>#{SIGNALS_SCRIPT}</script>"
    end

    private

    def session_like?(object)
      object.respond_to?(:[]) && object.respond_to?(:[]=)
    end

    def stringify_keys(attrs)
      attrs.to_h { |key, value| [key.to_s.tr("_", "-"), value] }
    end

    def tag(name, attrs)
      pairs = attrs.compact.map do |key, value|
        next CGI.escape_html(key.to_s) if value == true

        %(#{CGI.escape_html(key.to_s)}="#{CGI.escape_html(value.to_s)}")
      end
      "<#{name} #{pairs.join(" ")}>"
    end
  end
end
