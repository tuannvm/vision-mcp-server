# Vision MCP Server

A local-only OCR (Optical Character Recognition) MCP server for Claude Code. Extract text from images using Apple's native Vision Framework - fully offline, privacy-focused, no API keys required.

## Features

- Local-only processing (Apple Vision Framework)
- Offline capable, no network required
- Multi-language support (16+ languages)
- Base64 and file path input support
- Swift 6.1+ with modern concurrency

## Requirements

- macOS 13.0+
- Xcode 16+ or Swift 6.1+
- Claude Code (or MCP-compatible client)

## Quick Start

```bash
# Clone and build
git clone https://github.com/tuannvm/vision-mcp-server.git
cd vision-mcp-server
npm run build:release
```

Add to `~/.config/claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "local-ocr": {
      "command": "/path/to/vision-mcp-server/vision-mcp-server"
    }
  }
}
```

Restart Claude Code.

## Usage

Paste an image and ask:
> "Extract the text from this image"

Or specify parameters:
> "Extract Chinese text using fast recognition"

## Tool Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image` | string | *required* | Base64 data URL or file path |
| `languages` | array | `["en-US"]` | Recognition languages |
| `recognitionLevel` | string | `"accurate"` | `"fast"` or `"accurate"` |
| `usesLanguageCorrection` | boolean | `true` | Enable language model |

## Supported Languages

`en-US`, `zh-Hans`, `zh-Hant`, `ja`, `ko`, `es`, `fr`, `de`, `it`, `pt-BR`, `ru`, `ar`, `th`, `vi`, `nl`, `pl`, `tr`

[Full language list](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/3600635-recognitionlanguages)

## Documentation

- [Architecture](docs/architecture.md) - Technical design
- [development.md](docs/development.md) - Build & development guide

## License

MIT
