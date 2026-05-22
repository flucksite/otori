# frozen_string_literal: true

require_relative "../otori"

module Otori
  module Hanami
    module Action
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def honeypot(name, wait: nil, &on_caught)
          field_name = name
          field_wait = wait
          caught_block = on_caught

          before do |request, response|
            next unless Otori.caught?(
              field_name,
              params: request.params.to_h,
              session: request.session,
              wait: field_wait
            )

            if caught_block
              instance_exec(request, response, &caught_block)
            else
              halt 204
            end
          end
        end
      end
    end

    module Helpers
      def honeypot_field(name, **attrs)
        Otori.field(name, session: _otori_session, **attrs).html_safe
      end

      def honeypot_signals(**attrs)
        Otori.signals_field(**attrs).html_safe
      end

      private

      def _otori_session
        return context.request.session if respond_to?(:context) &&
                                          context.respond_to?(:request)
        return request.session if respond_to?(:request)

        raise Otori::MissingSession
      end
    end
  end
end
