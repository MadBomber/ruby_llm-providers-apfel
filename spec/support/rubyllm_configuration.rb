# frozen_string_literal: true

RSpec.shared_context 'with configured RubyLLM' do
  before do
    RubyLLM.configure do |config|
      config.apfel_api_key = ENV.fetch('APFEL_API_KEY', nil)
      config.apfel_api_base = ENV.fetch('APFEL_API_BASE', RubyLLM::Providers::Apfel::DEFAULT_API_BASE)
      config.max_retries = 0
      config.retry_backoff_factor = 0
      config.retry_interval = 0
      config.retry_interval_randomness = 0
    end
  end
end
