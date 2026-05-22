# frozen_string_literal: true

module Otori
  class Configuration
    SESSION_KEY_PREFIX = "honeypot_field"

    attr_accessor :default_delay, :disable_delay, :signals_input_name

    def initialize
      @default_delay = 2.0
      @disable_delay = false
      @signals_input_name = "honeypot_signals"
    end

    def session_key(name)
      safe = name.to_s.gsub(/[^a-z0-9_]+/i, "_").gsub(/\A_+|_+\z/, "")
      "#{SESSION_KEY_PREFIX}_#{safe}"
    end
  end
end
