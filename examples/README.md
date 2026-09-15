# Examples

Demo apps showing how to use the `ruby_llm-providers-apfel` gem with RubyLLM. Each demo is a
self-contained script; shared setup lives in `common.rb`, which every demo loads with
`require_relative 'common'`.

## Running a demo

```sh
brew install apfel
apfel --serve
bundle exec ruby examples/01_basic_usage.rb
```

Override the server URL, key, or model with `APFEL_API_BASE`, `APFEL_API_KEY`, or `APFEL_MODEL`
(see `common.rb`).

## Demos

| File | Shows |
| --- | --- |
| `01_basic_usage.rb` | The simplest possible `chat.ask` round trip. |
| `02_streaming_response.rb` | Streaming a response chunk by chunk. |
| `03_multi_turn_conversation.rb` | A `Chat` instance retaining conversation history across turns. |
| `04_tool_calling.rb` | Registering a local `RubyLLM::Tool` the model can call. |
| `05_structured_output.rb` | Constraining a response to a JSON Schema with `with_schema`. |
| `06_list_models.rb` | Querying `GET /v1/models` instead of hardcoding a model id. |
| `07_with_capabilities.rb` | Chaining every `with_*` Chat method that actually affects an Apfel request. |
| `08_mcp_server_tools.rb` | A plain `chat.ask` using `demo_mcp_server.rb`'s tool via `--mcp`, then probing whether its resource is reachable the same way (it isn't). |

## `apfel --serve` options

Recap of `apfel --serve`'s relevant flags (from `apfel --help`, v1.10.0):

| Flag | Purpose |
| --- | --- |
| `--port <number>` | Server port (default `11434`) |
| `--host <address>` | Bind address (default `127.0.0.1`, loopback-only) |
| `--token <secret>` | Require a Bearer token for auth |
| `--token-auto` | Generate and print a random Bearer token instead of choosing your own |
| `--cors` | Enable CORS headers, for browser-based clients |
| `--allowed-origins <origins>` | Comma-separated list added to the localhost defaults |
| `--no-origin-check` | Disable origin checking entirely |
| `--public-health` | Keep `/health` unauthenticated even when bound to a non-loopback address |
| `--footgun` | Shortcut for `--no-origin-check --cors` — disables all network protections at once |
| `--max-concurrent <n>` | Max concurrent model requests (default `5`) |

Matching environment variables: `APFEL_HOST`, `APFEL_PORT`, `APFEL_TOKEN` — same defaults as
above, useful if you'd rather not put the port or token on the command line.

Also relevant when serving:

- `--mcp <path|url>` (repeatable) — attach a local or remote MCP tool server. Tools are
  auto-discovered, called, and fed back into the conversation entirely inside Apfel — clients see
  a plain chat response, no `tools` field needed. See `08_mcp_server_tools.rb` and the
  `demo_mcp_server.rb` server (built with the `fast-mcp` gem) it exercises.
- `--context-strategy`, `--context-max-turns`, `--context-output-reserve` — control how
  conversation history is trimmed to fit the 4,096-token context window.
- `--debug` — logs to stderr; useful for diagnosing the tool-calling flakiness described in
  `04_tool_calling.rb`.

Example: `apfel --serve --port 3000 --host 0.0.0.0 --cors`

If you change the port or host, set `APFEL_API_BASE` before running a demo, for example:

```sh
APFEL_API_BASE=http://127.0.0.1:3000/v1 bundle exec ruby examples/01_basic_usage.rb
```
