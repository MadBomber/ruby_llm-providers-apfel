#!/usr/bin/env ruby
# frozen_string_literal: true

# 06_list_models.rb
#
# Queries Apfel's model-listing endpoint (GET /v1/models) instead of
# hardcoding a model id. RubyLLM's own `provider.list_models` (used by this
# gem's `rake models` task) trims the response down to a portable Model
# object, dropping Apfel-specific fields, so this demo reads the raw
# response through the same provider connection to show everything Apfel
# reports: context window, and supported/unsupported request parameters.
#
# Setup: see common.rb (requires `apfel --serve` running).
#
# Run:
#   bundle exec ruby examples/06_list_models.rb

require_relative 'common'

begin
  provider   = RubyLLM::Provider.resolve!(:apfel).new(RubyLLM.config)
  raw_models = provider.connection.get('models').body['data']

  abort 'Apfel returned no models.' if raw_models.to_a.empty?

  raw_models.each do |model|
    puts <<~MODEL
      Id:                  #{model['id']}
      Owned by:            #{model['owned_by']}
      Context window:      #{model['context_window']} tokens
      Supported params:    #{model['supported_parameters']&.join(', ')}
      Unsupported params:  #{model['unsupported_parameters']&.join(', ')}
      Notes:               #{model['notes']}

    MODEL
  end
rescue RubyLLM::Error => e
  # `warn` is silenced by Bundler ($VERBOSE is nil under `bundle exec`), so write to $stderr directly.
  $stderr.puts e.message # rubocop:disable Style/StderrPuts
  exit 1
end
