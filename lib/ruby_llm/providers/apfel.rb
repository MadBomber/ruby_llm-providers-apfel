# frozen_string_literal: true

require 'ruby_llm'
require 'ruby_llm/providers/apfel/version'
require 'ruby_llm/providers/apfel/connection_guard'

module RubyLLM
  module Providers
    # Apfel API integration.
    class Apfel < Provider
      # Apfel's ChatCompletions protocol.
      class ChatCompletions < Protocols::ChatCompletions
        def models_url
          'models'
        end
      end

      protocol :chat_completions, ChatCompletions

      def initialize(config)
        super
        @connection = ConnectionGuard.new(@connection)
      end

      def api_base
        @config.apfel_api_base || 'https://api.example.com/v1'
      end

      def headers
        { 'Authorization' => "Bearer #{@config.apfel_api_key}" }
      end

      class << self
        def configuration_options
          %i[apfel_api_key apfel_api_base]
        end

        def configuration_requirements
          %i[apfel_api_key]
        end

        # Use this only when the provider has no model-listing endpoint.
        # def assume_models_exist?
        #   true
        # end
      end
    end
  end
end

RubyLLM::Provider.register :apfel, RubyLLM::Providers::Apfel,
                           models: File.expand_path('../../../models.json', __dir__)
