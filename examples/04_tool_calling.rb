#!/usr/bin/env ruby
# frozen_string_literal: true

# 04_tool_calling.rb
#
# Registers a local Ruby tool the model can call. When it decides the
# question needs the tool, RubyLLM runs #execute and feeds the result back
# to the model, matching Apfel's declared `tools` / `tool_choice` support.
#
# Setup: see common.rb (requires `apfel --serve` running).
#
# Run:
#   bundle exec ruby examples/04_tool_calling.rb
#
# Known flakiness: Apple's on-device model hallucinates/renames tool
# arguments and occasionally errors out or returns no text after a tool
# call. This is expected, not a bug — see Apfel's tool-calling guide:
# https://github.com/Arthur-Ficial/apfel/blob/main/docs/tool-calling-guide.md

require_relative 'common'

# A tool with no external dependencies, so it works fully offline like Apfel itself.
class RollDice < RubyLLM::Tool
  description 'Rolls an N-sided die and returns the result'
  parameter :sides, type: :integer, description: 'Number of sides on the die', required: false

  def execute(sides: 6)
    puts "INFO: tool called with sides: #{sides}"
    { sides: sides, result: rand(1..sides) }
  end
end

begin
  # The tool-calling guide recommends telling the model it MUST use the tool;
  # this measurably improves reliability with Apple's on-device model.
  chat = RubyLLM.chat(model: MODEL, provider: :apfel, assume_model_exists: true)
                .with_instructions('You MUST use the roll_dice function to answer this request.')
                .with_tools(RollDice)
  prompt   = 'Roll a 20-sided die and tell me what number came up.'
  response = chat.ask(prompt)
  answer   = response.content.to_s.strip

  # Apple's small on-device model occasionally calls the tool but returns no
  # follow-up text. That is not an error RubyLLM raises, so handle it here.
  if answer.empty?
    answer = '(Apfel returned no text after the tool call this time. This is normal on-device ' \
             'model flakiness, not a bug — try running the example again.)'
  end

  puts <<~OUTPUT
    Prompt: #{prompt}
    Answer: #{answer}
  OUTPUT
rescue RubyLLM::Error => e
  # `warn` is silenced by Bundler ($VERBOSE is nil under `bundle exec`), so write to $stderr directly.
  $stderr.puts e.message # rubocop:disable Style/StderrPuts
  exit 1
rescue TypeError => e
  # The model sometimes hallucinates tool-call arguments as a JSON array
  # instead of an object; RubyLLM does not guard against that shape, so it
  # raises a raw TypeError instead of a RubyLLM::Error. See the tool-calling
  # guide linked above.
  $stderr.puts "Apfel sent malformed tool-call arguments: #{e.message}" # rubocop:disable Style/StderrPuts
  exit 1
end
