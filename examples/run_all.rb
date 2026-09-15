#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs every numbered demo in this directory — any file matching
# NN_*.rb — in numerical order, with a banner before each one.
#
#   ruby examples/run_all.rb

DEMO_PATTERN = /\A(\d+)_.*\.rb\z/
REPO_ROOT = File.expand_path('..', __dir__)

def demo_files(dir)
  Dir.children(dir)
     .filter_map { |name| (match = DEMO_PATTERN.match(name)) && [match[1].to_i, name] }
     .sort
     .map { |_number, name| File.join(dir, name) }
end

def banner(text, width: 70)
  <<~BANNER

    #{'=' * width}
    ==  #{text}
    #{'=' * width}

  BANNER
end

def run_demo(path)
  system(RbConfig.ruby, path, chdir: REPO_ROOT)
end

demos = demo_files(__dir__)
failures = []

demos.each do |path|
  puts banner(File.basename(path))
  failures << File.basename(path) unless run_demo(path)
end

puts banner("#{demos.length - failures.length} of #{demos.length} demos succeeded")

unless failures.empty?
  puts "failed: #{failures.join(', ')}"
  exit 1
end
