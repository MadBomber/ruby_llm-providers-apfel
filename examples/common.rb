# frozen_string_literal: true

# common.rb
#
# Shared setup for the numbered demo apps in this directory: loads the gem,
# points RubyLLM at a local Apfel server, and makes sure that server exists.
#
# If `apfel` is not on $PATH it is installed with Homebrew (`brew install apfel`).
# If nothing is answering at the configured api_base, `apfel --serve` is started
# in the background and left running for later demos. Its output goes to
# tmp/apfel-server.log in the repo root. Stop it with: pkill -f 'apfel --serve'
#
# Set APFEL_NO_AUTOSTART=1 to skip all of this and manage the server yourself.

require 'bundler/setup'
require 'ruby_llm/providers/apfel'
require 'fileutils'
require 'net/http'
require 'uri'

RubyLLM.configure do |config|
  config.apfel_api_base = ENV.fetch('APFEL_API_BASE', 'http://127.0.0.1:11434/v1')
  # Apfel does not require a key unless the server was started with `apfel --serve --token <value>`.
  config.apfel_api_key = ENV.fetch('APFEL_API_KEY', 'not-required')
end

MODEL = ENV.fetch('APFEL_MODEL', 'apple-foundationmodel')

# Installs the apfel CLI and starts its OpenAI-compatible server when needed.
module ApfelServer
  LOCAL_HOSTS   = %w[127.0.0.1 localhost ::1].freeze
  START_TIMEOUT = 30 # seconds
  LOG_PATH      = File.expand_path('../tmp/apfel-server.log', __dir__)

  module_function

  def ensure_running!(api_base)
    uri = URI(api_base)
    return if listening?(uri)

    unless local?(uri)
      abort "No Apfel server is answering at #{api_base}, and it is not local, so it cannot be started here."
    end

    ensure_installed!
    start!(uri)
  end

  def local?(uri) = LOCAL_HOSTS.include?(uri.host)

  def command?(name) = system("command -v #{name} >/dev/null 2>&1")

  def ensure_installed!
    return if command?('apfel')

    abort 'apfel is not on $PATH and Homebrew was not found; see https://brew.sh' unless command?('brew')

    notice 'apfel not found on $PATH; installing with Homebrew...'
    abort 'brew install apfel failed.' unless system('brew', 'install', 'apfel')
  end

  # True when anything answers HTTP on the server's port; connection errors mean nothing is listening.
  def listening?(uri)
    Net::HTTP.start(uri.host, uri.port, open_timeout: 1, read_timeout: 2) { |http| http.get('/health') }
    true
  rescue SystemCallError, IOError, Net::OpenTimeout, Net::ReadTimeout, SocketError
    false
  end

  def start!(uri)
    FileUtils.mkdir_p(File.dirname(LOG_PATH))
    notice "Starting apfel --serve on #{uri.host}:#{uri.port} (log: #{LOG_PATH})..."

    pid = Process.spawn('apfel', '--serve', '--host', uri.host, '--port', uri.port.to_s,
                        in: File::NULL, out: [LOG_PATH, 'a'], err: %i[child out], pgroup: true)
    Process.detach(pid)

    wait_until_listening!(uri, pid)
  end

  def wait_until_listening!(uri, pid, timeout: START_TIMEOUT)
    deadline = now + timeout

    until listening?(uri)
      abort "apfel --serve exited during startup; see #{LOG_PATH}" unless alive?(pid)
      abort "apfel --serve did not start within #{timeout}s; see #{LOG_PATH}" if now > deadline

      sleep 0.25
    end
  end

  def alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  end

  def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  # `warn` is silenced by Bundler ($VERBOSE is nil under `bundle exec`), so write to $stderr directly.
  def notice(message) = $stderr.puts(message) # rubocop:disable Style/StderrPuts
end

ApfelServer.ensure_running!(RubyLLM.config.apfel_api_base) unless ENV['APFEL_NO_AUTOSTART']
