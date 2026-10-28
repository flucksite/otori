# frozen_string_literal: true

require "json"

module Otori
  class Signals
    KEYS = {
      mouse: "m",
      touch: "t",
      scroll: "s",
      keyboard: "k",
      focus: "f"
    }.freeze

    def self.from_json(json)
      raw = JSON.parse(json.to_s)
      raise JSON::ParserError, "expected an object" unless raw.is_a?(Hash)

      new(KEYS.transform_values { raw[it] == true })
    rescue JSON::ParserError
      new
    end

    def self.human_rating(json)
      from_json(json).human_rating
    end

    def self.pragmatic_rating(json)
      from_json(json).pragmatic_rating
    end

    # Touchless devices can trigger at most four signals, capping them at 0.8,
    # so this stretches 0.4-0.8 to 0.4-1.0 to let them rate as fully human.
    PRAGMATIC_ANCHOR = 0.4
    PRAGMATIC_CLEAN = 0.8

    def initialize(flags = {})
      @flags = KEYS.keys.to_h { [it, flags.fetch(it, false) == true] }
    end

    KEYS.each_key do |key|
      define_method("#{key}?") { @flags.fetch(key) }
    end

    def human_rating
      @flags.values.count(true) / KEYS.size.to_f
    end

    def pragmatic_rating
      raw = human_rating
      return raw if raw <= PRAGMATIC_ANCHOR
      return 1.0 if raw >= PRAGMATIC_CLEAN

      span = (1.0 - PRAGMATIC_ANCHOR) / (PRAGMATIC_CLEAN - PRAGMATIC_ANCHOR)
      (PRAGMATIC_ANCHOR + (raw - PRAGMATIC_ANCHOR) * span).round(2)
    end

    def to_h = @flags.dup
  end
end
