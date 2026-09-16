# ruby_llm-providers-apfel

RubyLLM provider gem for [Apfel](https://apfel.franzai.com/), a CLI tool that exposes Apple's
on-device Foundation Models framework through an OpenAI-compatible HTTP server. With Apfel and
this gem, RubyLLM can talk to Apple's on-device model (AFM) as a fully local, offline LLM
provider — no API key, no cloud calls, no per-token billing.

## Requirements

- Apple Silicon Mac (M-series)
- macOS 26 (Tahoe) or later
- Apple Intelligence enabled

## Installing Apfel

Apfel itself is a separate Homebrew package, not a Ruby gem. Install it once per machine:

```sh
brew install apfel
```

Start it as a local OpenAI-compatible server:

```sh
apfel --serve
```

By default the server listens at `http://127.0.0.1:11434/v1`. Authentication is optional — pass
`--token <value>` to `apfel --serve` if you want to require a Bearer token; otherwise no API key
is needed at all.

Apfel serves Apple's on-device Foundation Model (AFM, ~3B parameters) running entirely on the
Neural Engine. It has a combined input/output context window of 4,096 tokens, so keep prompts and
expected responses within that budget.

## Installing the gem

Add this line to your application's Gemfile:

```ruby
gem 'ruby_llm-providers-apfel', require: 'ruby_llm/providers/apfel'
```

The provider works out of the box against Apfel's default address
(`http://127.0.0.1:11434/v1`) with no API key, so no configuration is required:

```ruby
require 'ruby_llm/providers/apfel'
```

Configure it only to override the defaults:

```ruby
RubyLLM.configure do |config|
  # Only needed when the server listens somewhere else
  config.apfel_api_base = ENV.fetch('APFEL_API_BASE', nil)
  # Only needed if you started `apfel --serve --token <value>`
  config.apfel_api_key = ENV.fetch('APFEL_API_KEY', nil)
end
```

## Usage

```ruby
model = RubyLLM.models.by_provider(:apfel).chat_models.first
chat = RubyLLM.chat(model: model.id)
response = chat.ask('Hello')
puts response.content
```

## Development

The generator installs the bundle and creates an ignored `.env`. Edit the generated `op read` reference so it points to your 1Password credential. If you do not use the 1Password CLI, replace the expression with the provider key.

```sh
bundle exec rake models
bundle exec rake
```

`rake models` calls only Apfel's model-listing endpoint and writes `models.json` at the gem root. RubyLLM loads that catalog as a fallback when this provider is registered, so applications do not need to combine registry files. The main RubyLLM registry always wins when both catalogs carry the same model. If the API uses a different path, change `models_url` in `lib/ruby_llm/providers/apfel.rb`.

Run `rake models` from this provider gem when you want to update its packaged catalog. `RubyLLM.models.refresh` updates the application's main registry and does not refresh provider gem catalogs.

If the provider has no model-listing endpoint, uncomment `assume_models_exist?` in the provider and do not run `rake models`.

The suite always runs the provider integration specs. The first local run calls the API and records VCR cassettes; CI only replays committed cassettes. A failing example deletes its cassette so the next local run tests the live API again.

After refreshing the catalog, add real model IDs to `spec/support/models.rb`. Keep only the operation matrices the provider supports. The portable contract specs are adapted from [RubyLLM's live specs](https://github.com/crmne/ruby_llm/tree/main/spec/ruby_llm); use those as the reference when your provider needs coverage for another feature or dialect.
