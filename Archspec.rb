# frozen_string_literal: true

source 'lib/**/*.rb'

component :provider,
          in: %w[
            lib/ruby_llm/providers/apfel.rb
            lib/ruby_llm/providers/apfel/**/*.rb
          ],
          namespace: 'RubyLLM::Providers::Apfel'

provider.cannot_reference_constants 'RSpec', 'WebMock', 'VCR'

preset :ruby_conventions
