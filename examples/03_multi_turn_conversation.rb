#!/usr/bin/env ruby
# frozen_string_literal: true

# 03_multi_turn_conversation.rb
#
# A single Chat instance keeps its own conversation history, so later
# questions can refer back to earlier turns without resending them.
#
# Setup: see common.rb (requires `apfel --serve` running).
#
# Run:
#   bundle exec ruby examples/03_multi_turn_conversation.rb

require_relative 'common'

PROMPTS = [
  'My favorite color is teal. Remember that.',
  'What did I just tell you my favorite color was?'
].freeze

begin
  chat = RubyLLM.chat(model: MODEL, provider: :apfel, assume_model_exists: true)

  PROMPTS.each do |prompt|
    response = chat.ask(prompt)
    puts <<~TURN
      You:    #{prompt}
      Apfel:  #{response.content}

    TURN
  end
rescue RubyLLM::Error => e
  # `warn` is silenced by Bundler ($VERBOSE is nil under `bundle exec`), so write to $stderr directly.
  $stderr.puts e.message # rubocop:disable Style/StderrPuts
  exit 1
end
