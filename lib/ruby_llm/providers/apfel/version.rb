# frozen_string_literal: true

module RubyLLM
  module Providers
    # Version of the ruby_llm-providers-apfel gem. Kept in its own file so the
    # gemspec can read the literal without loading the provider.
    class Apfel < Provider
      VERSION = '0.2.0'

      def self.version
        VERSION
      end
    end
  end
end
