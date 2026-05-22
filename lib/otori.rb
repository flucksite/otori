# frozen_string_literal: true

require_relative "otori/version"
require_relative "otori/error"
require_relative "otori/configuration"
require_relative "otori/signals"
require_relative "otori/validator"
require_relative "otori/form"

module Otori
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
      config
    end

    def reset_config!
      @config = Configuration.new
    end

    def field(name, session:, **attrs)
      Form.field(name, session: session, **attrs)
    end

    def signals_field(**attrs)
      Form.signals_field(**attrs)
    end

    def caught?(name, params:, session:, wait: nil)
      wait ||= config.default_delay
      session_key = config.session_key(name)
      stored = session_get(session, session_key)
      filled = Validator.filled?(param_value(params, name))
      elapsed = Validator.elapsed?(stored&.to_i, wait)

      if !filled && elapsed
        session_delete(session, session_key)
        false
      else
        session[session_key] = Validator.monotonic_ms.to_s
        true
      end
    end

    def signals_rating(params)
      raw = param_value(params, config.signals_input_name)
      return 0.0 if raw.nil? || raw.to_s.empty?

      Signals.human_rating(raw.to_s)
    end

    private

    def param_value(params, name)
      param_keys(name).reduce(params) do |scope, key|
        break nil unless scope.respond_to?(:[])

        scope[key] || scope[key.to_sym]
      end
    end

    def param_keys(name)
      keys = name.to_s.scan(/[^\[\]]+/)
      keys.empty? ? [name.to_s] : keys
    end

    def session_get(session, key)
      session[key] || session[key.to_sym]
    end

    def session_delete(session, key)
      session.delete(key) if session.respond_to?(:delete)
    end
  end
end
