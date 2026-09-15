#!/usr/bin/env ruby
# frozen_string_literal: true

# 02_streaming_response.rb
#
# Streams a response chunk by chunk instead of waiting for the full answer,
# using Apfel's OpenAI-compatible SSE streaming support.
#
# Setup: see common.rb (requires `apfel --serve` running).
#
# Run:
#   bundle exec ruby examples/02_streaming_response.rb

require_relative 'common'

begin
  chat   = RubyLLM.chat(model: MODEL, provider: :apfel, assume_model_exists: true)
  prompt = 'explain all the ways in which the MacOS and Apple Intelligence are better that the standard WinTel-based PC'

  print "Prompt: #{prompt}\nAnswer: "
  chat.ask(prompt) { |chunk| print chunk.content }
  puts
rescue RubyLLM::Error => e
  # `warn` is silenced by Bundler ($VERBOSE is nil under `bundle exec`), so write to $stderr directly.
  $stderr.puts e.message # rubocop:disable Style/StderrPuts
  exit 1
end
