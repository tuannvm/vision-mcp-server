# Vision MCP Server

[![npm version](https://img.shields.io/npm/v/@tuannvm/vision-mcp-server.svg)](https://www.npmjs.com/package/@tuannvm/vision-mcp-server)
[![license](https://img.shields.io/npm/l/@tuannvm/vision-mcp-server.svg)](https://www.npmjs.com/package/@tuannvm/vision-mcp-server)

Local-only OCR MCP server using Apple Vision Framework. Fully offline, privacy-focused text extraction from images directly in Claude Code.

```mermaid
graph LR
    A[Claude Code] --> B[Vision MCP Server]
    B --> C[Apple Vision Framework]
    C --> D[Local Text Extraction]

    style A fill:#FF6B35
    style B fill:#4A90E2
    style C fill:#00D4AA
    style D fill:#FFA500
```

## Quick Start

### 1. Install the Server

```bash
claude mcp add local-ocr -- npx -y @tuannvm/vision-mcp-server
```

### 2. Start Using

```
Extract the text from this image
Extract Chinese text using fast recognition
```

## One-Click Install

[![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?style=flat-square&logo=visualstudiocode&logoColor=white)](https://vscode.dev/redirect/mcp/install?name=local-ocr&config=%7B%22type%22%3A%22stdio%22%2C%22command%22%3A%22npx%22%2C%22args%22%3A%5B%22-y%22%2C%22%40tuannvm%2Fvision-mcp-server%22%5D%7D)
[![VS Code Insiders](https://img.shields.io/badge/VS_Code_Insiders-Install-24bfa5?style=flat-square&logo=visualstudiocode&logoColor=white)](https://insiders.vscode.dev/redirect/mcp/install?name=local-ocr&config=%7B%22type%22%3A%22stdio%22%2C%22command%22%3A%22npx%22%2C%22args%22%3A%5B%22-y%22%2C%22%40tuannvm%2Fvision-mcp-server%22%5D%7D)
[![Cursor](https://img.shields.io/badge/Cursor-Install-00D8FF?style=flat-square&logo=cursor&logoColor=white)](https://cursor.com/en/install-mcp?name=local-ocr&config=eyJ0eXBlIjoic3RkaW8iLCJjb21tYW5kIjoibnB4IC15IEB0dWFubnZtL3Zpc2lvbi1tY3Atc2VydmVyIiwiZW52Ijp7fX0%3D)

## Tools

| Tool | Description |
|------|-------------|
| `ocr_extract_text` | Extract text from images using Apple Vision Framework |

## Examples

The tool automatically detects the input format:

**Pasted Images (Base64):**
```
Extract the text from this image
```
When you paste an image in Claude Code, it's automatically converted to base64 format.

**Local File Paths:**
```
Read text from /Users/username/Desktop/screenshot.png
Extract text from ~/Downloads/receipt.jpg
```

**Remote URLs:**
```
Extract text from https://example.com/screenshot.jpg
OCR the image at https://example.org/photo.png
```

**Multi-language extraction:**
```
Extract Chinese and Japanese text from this screenshot
```

**Fast recognition mode:**
```
Extract text using fast recognition mode
```

**Advanced options:**
```
Extract text with recognition level "fast" and language correction disabled
```

## Requirements

- **macOS 13.0+** — Apple Vision Framework is built into macOS
- **Node.js 18+** — Required for MCP server runtime
- **Apple Silicon or Intel** — Both arm64 and x64 are supported

## Supported Languages

`en-US`, `zh-Hans`, `zh-Hant`, `ja`, `ko`, `es`, `fr`, `de`, `it`, `pt-BR`, `ru`, `ar`, `th`, `vi`, `nl`, `pl`, `tr`

[Full language list](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/3600635-recognitionlanguages)

## Documentation

- **[API Reference](docs/api-reference.md)** — Full tool parameters and response formats
- **[Architecture](docs/architecture.md)** — Technical design details

## Development

```bash
npm install         # Install dependencies
npm run build       # Build Swift binary
npm run build:release  # Build optimized release binary
npm test            # Run tests
```

## Related Projects

- **[codex-mcp-server](https://github.com/tuannvm/codex-mcp-server)** — MCP server for OpenAI Codex CLI with AI-powered code analysis and review
- **[gemini-mcp-server](https://github.com/tuannvm/gemini-mcp-server)** — MCP server for Gemini CLI with 1M+ token context, web search, and media analysis

## License

MIT
