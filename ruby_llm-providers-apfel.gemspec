# frozen_string_literal: true

# Read the literal rather than loading the provider: the gemspec is evaluated
# before this gem's lib/ is on the load path, so requiring it would resolve
# against an installed copy of the gem instead.
gem_version = File.read(File.expand_path('lib/ruby_llm/providers/apfel/version.rb', __dir__))[/VERSION = '([^']+)'/, 1]

Gem::Specification.new do |spec|
  spec.name = 'ruby_llm-providers-apfel'
  spec.version = gem_version
  spec.authors = ['madbomber']
  spec.email = ['dvanhoozer@gmail.com']

  spec.summary = 'RubyLLM provider for Apfel.'
  spec.description = 'Adds Apfel provider support to RubyLLM. Apfel is a macOS-only local server ' \
                     "that exposes Apple's on-device Apple Intelligence model over an " \
                     'OpenAI-compatible API, letting RubyLLM talk to it like any other provider.'
  spec.homepage = 'https://github.com/madbomber/ruby_llm-providers-apfel'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('{lib,spec}/**/*') +
               Dir.glob('.github/workflows/*.yml') +
               Dir.glob('models.json') +
               %w[.flayignore .overcommit.yml .rspec .rubocop.yml Archspec.rb LICENSE README.md]
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby_llm', '>= 2.0.0.rc1'
end
