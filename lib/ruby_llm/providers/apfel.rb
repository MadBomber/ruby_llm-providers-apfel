# frozen_string_literal: true

require 'ruby_llm'
require 'ruby_llm/providers/apfel/version'
require 'ruby_llm/providers/apfel/connection_guard'

module RubyLLM
  module Providers
    # Apfel — Apple's on-device Foundation Model (AFM) exposed as a local
    # OpenAI-compatible server by the `apfel` CLI (`apfel --serve`).
    # Works out of the box against http://127.0.0.1:11434/v1 — no API key
    # required (set apfel_api_key only when the server was started with
    # `apfel --serve --token <value>`).
    class Apfel < Provider
      DEFAULT_API_BASE = 'http://127.0.0.1:11434/v1'

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
        @config.apfel_api_base || DEFAULT_API_BASE
      end

      def headers
        return {} unless @config.apfel_api_key

        { 'Authorization' => "Bearer #{@config.apfel_api_key}" }
      end

      class << self
        def configuration_options
          %i[apfel_api_key apfel_api_base]
        end

        def configuration_requirements
          []
        end

        def local?
          true
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
