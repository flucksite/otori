# frozen_string_literal: true

RSpec.describe RackHoneypot::Signals do
  describe ".from_json" do
    it "parses each signal key" do
      json = '{"m":true,"t":false,"s":true,"k":false,"f":true}'
      signals = described_class.from_json(json)

      expect(signals.mouse?).to be(true)
      expect(signals.touch?).to be(false)
      expect(signals.scroll?).to be(true)
      expect(signals.keyboard?).to be(false)
      expect(signals.focus?).to be(true)
    end

    it "defaults missing keys to false" do
      signals = described_class.from_json("{}")
      expect(signals.to_h.values).to all(be(false))
    end

    it "treats invalid JSON as a fully-false set" do
      signals = described_class.from_json("not json")
      expect(signals.human_rating).to eq(0.0)
    end

    it "treats non-object JSON as a fully-false set" do
      signals = described_class.from_json("[1,2,3]")
      expect(signals.human_rating).to eq(0.0)
    end
  end

  describe "#human_rating" do
    it "returns the fraction of triggered signals" do
      signals = described_class.new(mouse: true, focus: true)
      expect(signals.human_rating).to eq(0.4)
    end

    it "returns 0 for a fully-bot submission" do
      expect(described_class.new.human_rating).to eq(0.0)
    end

    it "returns 1 for a fully-human submission" do
      signals = described_class.new(mouse: true, touch: true, scroll: true, keyboard: true, focus: true)
      expect(signals.human_rating).to eq(1.0)
    end
  end

  describe ".human_rating" do
    it "is a convenience class method" do
      json = '{"m":true,"f":true}'
      expect(described_class.human_rating(json)).to eq(0.4)
    end
  end
end
