#!/usr/bin/env ruby
# frozen_string_literal: true

# demo_mcp_server.rb
#
# A standalone MCP server (built with the fast-mcp gem) for
# 08_mcp_server_tools.rb to demo. It exposes:
#
#   - a tool, current_time, that Apfel's on-device model has no way to
#     answer correctly on its own
#   - a resource, demo/server-info, to check whether Apfel's --mcp bridge
#     forwards MCP resources the way it forwards tools. Apfel's own docs
#     only describe auto-discovering and calling tools ("Auto-discovers
#     tools via MCP tools/list at startup"); resources/list and
#     resources/read are never mentioned, so this is expected NOT to be
#     reachable through Apfel — the resource is real and reachable by any
#     MCP client that speaks resources/list + resources/read directly to
#     this server, which is what makes it a genuine test rather than a
#     given.
#
# Speaks MCP over stdio, the transport `apfel --mcp` expects, so it is not
# run directly; a client (Apfel, or an MCP inspector) starts it as a
# subprocess.
#
# Only used as a demo prop for this gem's examples, so fast-mcp lives in the
# Gemfile's :development group rather than the gemspec's runtime dependencies.
#
# Setup:
#   apfel --serve --mcp examples/demo_mcp_server.rb
#
# Then run 08_mcp_server_tools.rb in another terminal.

require 'fast_mcp'
require 'json'
require 'socket'
require 'time'

# The one tool this server exposes over MCP.
class CurrentTimeTool < FastMcp::Tool
  tool_name 'current_time'
  description 'Returns the current date and time on the machine running this MCP server'

  def call(**_args)
    Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')
  end
end

# The one resource this server exposes over MCP — pid, Ruby version, and
# hostname of the process Apfel spawned, so a caller can tell whether it is
# reading this server's own answer versus something the model made up.
class ServerInfoResource < FastMcp::Resource # rubocop:disable Style/OneClassPerFile
  uri 'demo/server-info'
  resource_name 'Demo MCP Server Info'
  description 'Process info for the demo_mcp_server.rb subprocess'
  mime_type 'application/json'

  def content
    JSON.generate(
      pid: Process.pid,
      ruby_version: RUBY_VERSION,
      hostname: Socket.gethostname,
      started_at: Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')
    )
  end
end

server = FastMcp::Server.new(name: 'apfel-demo-mcp-server', version: '0.0.1')
server.register_tool(CurrentTimeTool)
server.register_resource(ServerInfoResource)
server.start
