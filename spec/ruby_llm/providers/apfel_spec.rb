# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::Apfel do
  subject(:provider) { described_class.new(config) }

  let(:config) do
    RubyLLM::Configuration.new.tap do |provider_config|
      provider_config.apfel_api_key = 'test-key'
      provider_config.apfel_api_base = 'https://example.test/v1'
    end
  end

  it 'is registered with RubyLLM' do
    expect(RubyLLM::Provider.resolve(:apfel)).to eq(described_class)
  end

  it 'registers a default protocol' do
    expect(described_class.protocols).to include(chat_completions: described_class::ChatCompletions)
  end

  it 'declares provider configuration' do
    expect(described_class.configuration_options).to eq(%i[apfel_api_key apfel_api_base])
    expect(described_class.configuration_requirements).to eq(%i[apfel_api_key])
  end

  it 'uses configured API base and bearer token' do
    expect(provider.api_base).to eq('https://example.test/v1')
    expect(provider.headers).to eq('Authorization' => 'Bearer test-key')
  end
end
