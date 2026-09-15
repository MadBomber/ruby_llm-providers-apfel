#!/usr/bin/env ruby
# frozen_string_literal: true

# 05_structured_output.rb
#
# Constrains the model's reply to a JSON Schema and reads it back as parsed
# data instead of free text, using Apfel's declared `response_format`
# support.
#
# Setup: see common.rb (requires `apfel --serve` running).
#
# Run:
#   bundle exec ruby examples/05_structured_output.rb

require_relative 'common'

# The JSON Schema the model's reply is constrained to.
class MovieSchema < Schematist::Schema
  string :title, description: 'Movie title'
  integer :year, description: 'Release year'
  string :genre, description: 'Primary genre'
end

begin
  chat     = RubyLLM.chat(model: MODEL, provider: :apfel, assume_model_exists: true).with_schema(MovieSchema)
  prompt   = 'Give me details about the movie Blade Runner.'
  response = chat.ask(prompt)

  puts <<~OUTPUT
    Prompt: #{prompt}
    Parsed: #{response.parsed.inspect}
  OUTPUT
rescue RubyLLM::Error => e
  # `warn` is silenced by Bundler ($VERBOSE is nil under `bundle exec`), so write to $stderr directly.
  $stderr.puts e.message # rubocop:disable Style/StderrPuts
  exit 1
end
