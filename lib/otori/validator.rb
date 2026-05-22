# frozen_string_literal: true

module Otori
  module Validator
    extend self

    def filled?(value)
      !value.nil? && !value.to_s.strip.empty?
    end

    def elapsed?(timestamp_ms, wait_seconds, now: monotonic_ms)
      return true if Otori.config.disable_delay
      return false if timestamp_ms.nil?

      (now - timestamp_ms.to_i) >= (wait_seconds.to_f * 1000)
    end

    def monotonic_ms = (Time.now.to_f * 1000).to_i
  end
end
