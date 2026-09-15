#!/usr/bin/env ruby
# frozen_string_literal: true

# 07_with_capabilities.rb
#
# Chains the Chat#with_* configuration methods that actually change a
# request against Apfel's chat_completions protocol: with_instructions,
# with_temperature, with_max_output_tokens, with_headers, with_tools, and
# with_schema.
#
# Left out on purpose: with_citations, with_caching, with_thinking,
# with_compaction, with_server_tools, with_end_user, with_fallbacks, and
# with_context all target hosted-provider features (Anthropic/OpenAI
# server-side search, prompt caching, extended thinking, ...) that Apfel's
# local, chat_completions-only endpoint has no backing for — RubyLLM would
# either send params Apfel ignores or a method would have nothing to show.
#
# Setup: see common.rb (requires `apfel --serve` running).
#
# Run:
#   bundle exec ruby examples/07_with_capabilities.rb

require_relative 'common'

# Reused from 04_tool_calling.rb.
class RollDice < RubyLLM::Tool
  description 'Rolls an N-sided die and returns the result'
  parameter :sides, type: :integer, description: 'Number of sides on the die', required: false

  def execute(sides: 6)
    { sides: sides, result: rand(1..sides) }
  end
end

# The JSON Schema the final reply is constrained to.
class DiceRollSchema < Schematist::Schema # rubocop:disable Style/OneClassPerFile
  integer :sides, description: 'Number of sides on the die that was rolled'
  integer :result, description: 'The number that came up'
end

def build_chat
  RubyLLM.chat(model: MODEL, provider: :apfel, assume_model_exists: true)
         .with_instructions('You are a terse, upbeat game-night host.')
         .with_temperature(0.7)
         .with_max_output_tokens(200)
         .with_headers('X-Demo' => '07_with_capabilities')
end

begin
  # with_instructions / with_temperature / with_max_output_tokens / with_headers
  chat = build_chat
  plain_prompt = 'In one sentence, hype up a game of dice.'
  plain_answer = chat.ask(plain_prompt).content.to_s.strip

  # + with_tools, continuing the same conversation.
  chat.with_tools(RollDice)
  tool_prompt = 'Roll a 6-sided die and tell me the result.'
  tool_answer = chat.ask(tool_prompt).content.to_s.strip
  if tool_answer.empty?
    tool_answer = '(no text after the tool call — on-device model flakiness, see 04_tool_calling.rb)'
  end

  # with_schema needs a fresh chat: mixing tool_choice and response_format
  # in one request is unreliable on this small on-device model.
  schema_chat   = build_chat.with_schema(DiceRollSchema)
  schema_prompt = 'A 20-sided die was rolled and came up 17. Report it.'
  schema_result = schema_chat.ask(schema_prompt).parsed

  puts <<~OUTPUT
    -- with_instructions / with_temperature / with_max_output_tokens / with_headers --
    Prompt: #{plain_prompt}
    Answer: #{plain_answer}

    -- + with_tools --
    Prompt: #{tool_prompt}
    Answer: #{tool_answer}

    -- with_schema (fresh chat) --
    Prompt: #{schema_prompt}
    Parsed: #{schema_result.inspect}
  OUTPUT
rescue RubyLLM::Error => e
  # `warn` is silenced by Bundler ($VERBOSE is nil under `bundle exec`), so write to $stderr directly.
  $stderr.puts e.message # rubocop:disable Style/StderrPuts
  exit 1
rescue TypeError => e
  # See 04_tool_calling.rb: the model sometimes hallucinates tool-call
  # arguments as a JSON array instead of an object.
  $stderr.puts "Apfel sent malformed tool-call arguments: #{e.message}" # rubocop:disable Style/StderrPuts
  exit 1
end
