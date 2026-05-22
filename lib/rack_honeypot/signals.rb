# frozen_string_literal: true

require "json"

module RackHoneypot
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

      new(KEYS.transform_values { raw[_1] == true })
    rescue JSON::ParserError
      new
    end

    def self.human_rating(json)
      from_json(json).human_rating
    end

    def initialize(flags = {})
      @flags = KEYS.keys.to_h { [_1, flags.fetch(_1, false) == true] }
    end

    KEYS.each_key do |key|
      define_method("#{key}?") { @flags.fetch(key) }
    end

    def human_rating
      @flags.values.count(true) / KEYS.size.to_f
    end

    def to_h = @flags.dup
  end
end
