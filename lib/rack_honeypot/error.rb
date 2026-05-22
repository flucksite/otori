# frozen_string_literal: true

module RackHoneypot
  class Error < StandardError; end

  class MissingSession < Error
    def initialize
      super(
        "RackHoneypot needs a session-like object (responding to []=, []) " \
          "to store the form-load timestamp. Enable sessions in your app."
      )
    end
  end
end
