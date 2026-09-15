#!/usr/bin/env ruby
# frozen_string_literal: true

# 01_basic_usage.rb
#
# The simplest possible use of RubyLLM with the Apfel provider: ask a single
# question and print the answer.
#
# Setup: see common.rb (requires `apfel --serve` running).
#
# Run:
#   bundle exec ruby examples/01_basic_usage.rb

require_relative 'common'

begin
  chat     = RubyLLM.chat(model: MODEL, provider: :apfel, assume_model_exists: true)
  prompt   = 'What is the capital of France?'
  response = chat.ask(prompt)

  puts <<~OUTPUT
    Model:   #{MODEL}
    Prompt:  #{prompt}
    Answer:  #{response.content}
  OUTPUT
rescue RubyLLM::Error => e
  # `warn` is silenced by Bundler ($VERBOSE is nil under `bundle exec`), so write to $stderr directly.
  $stderr.puts e.message # rubocop:disable Style/StderrPuts
  exit 1
end
