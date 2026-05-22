# frozen_string_literal: true

RSpec.describe RackHoneypot::Configuration do
  describe "#session_key" do
    it "prefixes the field name" do
      expect(subject.session_key("note")).to eq("honeypot_field_note")
    end

    it "collapses bracket notation into underscores" do
      expect(subject.session_key("user[website]"))
        .to eq("honeypot_field_user_website")
    end

    it "trims trailing underscores produced by closing brackets" do
      expect(subject.session_key("a[b][c]"))
        .to eq("honeypot_field_a_b_c")
    end

    it "accepts symbol input" do
      expect(subject.session_key(:note)).to eq("honeypot_field_note")
    end
  end
end
