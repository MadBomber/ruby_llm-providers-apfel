#!/usr/bin/env ruby
# frozen_string_literal: true

# 08_mcp_server_tools.rb
#
# Demonstrates Apfel's server-side MCP integration, which is architecturally
# different from 04_tool_calling.rb. There, a RubyLLM::Tool runs *client*
# side and RubyLLM sends `tools` / `tool_choice` on every request. Here, an
# MCP server attached with `apfel --serve --mcp <path>` is auto-discovered,
# called, and fed back into the conversation entirely inside Apfel — "zero
# extra tokens, zero code path changes" for the HTTP client. The Ruby code
# that talks to Apfel below is a completely ordinary `chat.ask`: no
# `with_tools`, no `RubyLLM::Tool` subclass, no tool_call handling. The
# prompt alone is what makes the MCP server get used.
#
# The MCP server itself, demo_mcp_server.rb, lives next to this file and
# exposes:
#
#   - a current_time tool — something Apfel's on-device model cannot answer
#     correctly without calling out to it
#   - a demo/server-info resource, tested below as a second prompt. Apfel's
#     docs only describe auto-discovering and calling *tools*; resources are
#     a separate MCP primitive with no equivalent in the OpenAI-compatible
#     chat completions wire format Apfel exposes, so this second prompt is
#     expected to fail even with --mcp attached — see demo_mcp_server.rb for
#     the reasoning, and prove the resource itself works with a real MCP
#     client (`resources/list` + `resources/read` over stdio).
#
# Unlike every other demo here, this one does not require_relative
# 'common' and does not expect an `apfel --serve` you started yourself. It
# starts its own Apfel server as a subprocess — in a background thread that
# captures and echoes its stdout/stderr — bound to a random free port so it
# never collides with a server you already have running, attaches
# demo_mcp_server.rb to it, and configures RubyLLM directly against that
# instance once it is confirmed to be up.
#
# Setup:
#   brew install apfel
#
# Run:
#   bundle exec ruby examples/08_mcp_server_tools.rb

require 'bundler/setup'
require 'net/http'
require 'ruby_llm/providers/apfel'
require 'socket'

MCP_SERVER_PATH = File.expand_path('demo_mcp_server.rb', __dir__)
MODEL = ENV.fetch('APFEL_MODEL', 'apple-foundationmodel')

def free_port
  probe = TCPServer.new('127.0.0.1', 0)
  probe.addr[1]
ensure
  probe&.close
end

# Spawns `apfel --serve` on +port+ with demo_mcp_server.rb attached via
# --mcp, and starts a thread that drains its merged stdout/stderr so the
# subprocess never blocks on a full pipe buffer.
def start_apfel(port)
  io = IO.popen(['apfel', '--serve', '--port', port.to_s, '--mcp', MCP_SERVER_PATH], err: %i[child out])
  reader = Thread.new do
    io.each_line { |line| puts "[apfel] #{line}" }
  rescue IOError
    nil # the pipe closes out from under the thread during shutdown; nothing left to read
  end
  { io: io, pid: io.pid, reader: reader }
rescue Errno::ENOENT
  abort 'apfel not found on PATH — install it with `brew install apfel` and try again.'
end

# Polls GET /v1/models until Apfel answers or the process exits early.
def wait_for_server(pid, port, timeout: 30)
  uri = URI("http://127.0.0.1:#{port}/v1/models")
  deadline = Time.now + timeout

  loop do
    return false if Process.waitpid(pid, Process::WNOHANG)

    begin
      Net::HTTP.start(uri.host, uri.port, open_timeout: 1, read_timeout: 1) { |http| http.get(uri) }
      return true
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, EOFError, SocketError, Net::OpenTimeout, Net::ReadTimeout
      return false if Time.now > deadline

      sleep 0.25
    end
  end
rescue Errno::ECHILD
  false
end

def stop_apfel(server)
  Process.kill('TERM', server[:pid])
  Process.waitpid(server[:pid])
rescue Errno::ESRCH, Errno::ECHILD
  nil
ensure
  server[:io].close unless server[:io].closed?
  server[:reader].join(5)
end

def ask(chat, prompt)
  [prompt, chat.ask(prompt).content.to_s.strip]
end

port   = free_port
server = start_apfel(port)

begin
  abort "Apfel did not come up on port #{port} within the timeout — see its output above." \
    unless wait_for_server(server[:pid], port)

  RubyLLM.configure do |config|
    config.apfel_api_base = "http://127.0.0.1:#{port}/v1"
    config.apfel_api_key = 'not-required'
  end

  chat = RubyLLM.chat(model: MODEL, provider: :apfel, assume_model_exists: true)

  tool_prompt, tool_answer = ask(chat, 'What is the current date and time right now?')
  resource_prompt, resource_answer = ask(
    chat, 'What is the process ID (pid) of the MCP server you are connected to?'
  )

  puts <<~OUTPUT

    -- tool: current_time --
    Prompt: #{tool_prompt}
    Answer: #{tool_answer}
    (a real timestamp here means the --mcp tool round trip worked)

    -- resource: demo/server-info --
    Prompt: #{resource_prompt}
    Answer: #{resource_answer}
    (expect a guess or refusal, not a real pid — Apfel's --mcp bridge only
    forwards tools/list + tools/call, not resources/list + resources/read,
    so this resource is unreachable through the model no matter how the
    prompt is worded)
  OUTPUT
rescue RubyLLM::Error => e
  # `warn` is silenced by Bundler ($VERBOSE is nil under `bundle exec`), so write to $stderr directly.
  $stderr.puts e.message # rubocop:disable Style/StderrPuts
  exit 1
rescue TypeError => e
  # See 04_tool_calling.rb: the model sometimes hallucinates tool-call
  # arguments as a JSON array instead of an object.
  $stderr.puts "Apfel sent malformed tool-call arguments: #{e.message}" # rubocop:disable Style/StderrPuts
  exit 1
ensure
  stop_apfel(server)
end
