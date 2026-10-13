# frozen_string_literal: true

require_relative "../otori"

module Otori
  module Rails
    module ControllerMacros
      def honeypot(name, wait: nil, only: nil, except: nil, &on_caught)
        filter_options = {}
        filter_options[:only] = only if only
        filter_options[:except] = except if except

        before_action(**filter_options) do
          reason = Otori.reason(name, params:, session:, wait:)
          next unless reason

          if on_caught
            instance_exec(reason, &on_caught)
          else
            head :no_content
          end
        end
      end
    end

    module Helpers
      def honeypot_field(name, **attrs)
        Otori.field(name, session: session, **attrs).html_safe
      end

      def honeypot_signals(**attrs)
        Otori.signals_field(**attrs).html_safe
      end
    end

    if defined?(::Rails::Railtie)
      class Railtie < ::Rails::Railtie
        initializer "otori.action_controller" do
          ActiveSupport.on_load(:action_controller) do
            extend Otori::Rails::ControllerMacros
          end
        end

        initializer "otori.action_view" do
          ActiveSupport.on_load(:action_view) do
            include Otori::Rails::Helpers
          end
        end
      end
    end
  end
end
