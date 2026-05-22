# frozen_string_literal: true

RSpec.describe Otori::Validator do
  describe ".filled?" do
    it "is false for nil" do
      expect(described_class.filled?(nil)).to be(false)
    end

    it "is false for an empty string" do
      expect(described_class.filled?("")).to be(false)
    end

    it "is false for whitespace" do
      expect(described_class.filled?("   ")).to be(false)
    end

    it "is true for any content" do
      expect(described_class.filled?("spam")).to be(true)
    end
  end

  describe ".elapsed?" do
    let(:now) { 1_000_000 }

    it "is true when enough time has passed" do
      result = described_class.elapsed?(now - 3_000, 2.0, now: now)
      expect(result).to be(true)
    end

    it "is false when not enough time has passed" do
      result = described_class.elapsed?(now - 1_000, 2.0, now: now)
      expect(result).to be(false)
    end

    it "is false when no timestamp is given" do
      expect(described_class.elapsed?(nil, 2.0, now: now)).to be(false)
    end

    it "is true when disable_delay is set" do
      Otori.config.disable_delay = true
      expect(described_class.elapsed?(nil, 2.0, now: now)).to be(true)
    end
  end
end
