# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Models do
  include_context 'with configured RubyLLM'

  it 'expects generated providers to add registry metadata before use' do
    expect(RubyLLM::Providers::Apfel.assume_models_exist?).to be(false)
  end
end
