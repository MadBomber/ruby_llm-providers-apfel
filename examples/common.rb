# frozen_string_literal: true

# common.rb
#
# Shared setup for the numbered demo apps in this directory: loads the gem
# and points RubyLLM at a local Apfel server.
#
# Before running any demo:
#   brew install apfel
#   apfel --serve

require 'bundler/setup'
require 'ruby_llm/providers/apfel'

RubyLLM.configure do |config|
  config.apfel_api_base = ENV.fetch('APFEL_API_BASE', 'http://127.0.0.1:11434/v1')
  # Apfel does not require a key unless the server was started with `apfel --serve --token <value>`.
  config.apfel_api_key = ENV.fetch('APFEL_API_KEY', 'not-required')
end

MODEL = ENV.fetch('APFEL_MODEL', 'apple-foundationmodel')
