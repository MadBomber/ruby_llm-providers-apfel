# frozen_string_literal: true

require 'delegate'

module RubyLLM
  module Providers
    class Apfel < Provider
      # Wraps the transport connection so a request against a server that
      # is not running surfaces as a RubyLLM::Error explaining how to start
      # Apfel, instead of a raw Faraday::ConnectionFailed.
      class ConnectionGuard < SimpleDelegator
        %i[get post patch delete].each do |verb|
          define_method(verb) do |*args, **kwargs, &block|
            __getobj__.public_send(verb, *args, **kwargs, &block)
          rescue Faraday::ConnectionFailed
            raise Error, unreachable_message
          end
        end

        def unreachable_message
          "Could not connect to the Apfel server at #{provider.api_base}. " \
            'Install it with `brew install apfel` if needed, then start it with `apfel --serve`, ' \
            'and try again.'
        end
      end
    end
  end
end
