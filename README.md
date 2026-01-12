# OCR MCP Server

A local-only OCR (Optical Character Recognition) MCP server for Claude Code that extracts text from images using Apple's native Vision Framework. Fully offline, privacy-focused, and requires no external API keys.

## Features

- ✅ **Local-only processing** - All OCR happens on your Mac using Apple's Vision Framework
- ✅ **Offline capable** - No network connection required
- ✅ **Privacy-focused** - Images never leave your device
- ✅ **Multi-language support** - Supports 16+ languages including English, Chinese, Japanese, Korean
- ✅ **Pasted image support** - Works with images you paste directly into Claude Code
- ✅ **Swift 6.1+** - Built with the latest Swift concurrency features
- ✅ **MCP Compliant** - Fully compatible with Model Context Protocol

## Requirements

- macOS 13.0+
- Xcode 16+ (or Swift 6.1+ command line tools)
- Claude Code (or any MCP-compatible client)

## Installation

### 1. Build the MCP Server

```bash
cd /Users/tuannvm/Projects/cli/vision-mcp-server
swift build -c release
```

The built binary will be at `.build/release/ocr-mcp-server`.

### 2. Configure Claude Code

Add the following to your Claude Code configuration file (`~/.config/claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "local-ocr": {
      "command": "/Users/tuannvm/Projects/cli/vision-mcp-server/.build/release/ocr-mcp-server"
    }
  }
}
```

**Important**: Replace the path above with the actual path to your built binary.

### 3. Restart Claude Code

Restart Claude Code for the configuration to take effect.

## Usage

Once configured, you can use the OCR tool directly in Claude Code:

### Example 1: Extract text from a pasted screenshot

1. Take a screenshot or copy an image to your clipboard
2. Paste it into Claude Code (Cmd+V)
3. Ask Claude to extract the text:

> "Extract the text from this image"

### Example 2: Extract text from a file

> "Extract text from the image at /Users/username/Desktop/screenshot.png"

### Example 3: Specify recognition parameters

> "Extract Chinese text from this image using fast recognition"

## Tool Parameters

The `ocr_extract_text` tool accepts the following parameters:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `image` | string | Yes | - | Base64-encoded image data (e.g., `data:image/png;base64,...`) or local file path |
| `languages` | array of strings | No | `["en-US"]` | Recognition languages (e.g., `["en-US", "zh-Hans"]`) |
| `recognitionLevel` | string | No | `"accurate"` | `"fast"` or `"accurate"` |
| `usesLanguageCorrection` | boolean | No | `true` | Enable language model for better accuracy |

## Supported Languages

| Language Code | Language |
|---------------|----------|
| `en-US` | English |
| `zh-Hans` | Chinese (Simplified) |
| `zh-Hant` | Chinese (Traditional) |
| `ja` | Japanese |
| `ko` | Korean |
| `es` | Spanish |
| `fr` | French |
| `de` | German |
| `it` | Italian |
| `pt-BR` | Portuguese (Brazil) |
| `ru` | Russian |
| `ar` | Arabic |
| `th` | Thai |
| `vi` | Vietnamese |
| `nl` | Dutch |
| `pl` | Polish |
| `tr` | Turkish |

For the complete list of supported languages, see [Apple's documentation](https://developer.apple.com/documentation/vision/vnrecognizetextrequest/3600635-recognitionlanguages).

## Development

### Project Structure

```
ocr-mcp-server/
├── Package.swift              # Swift package manifest
├── Sources/ocr-mcp-server/
│   ├── main.swift             # Entry point
│   ├── VisionOCR.swift        # Vision Framework wrapper
│   ├── MCPServer.swift        # MCP protocol setup
│   ├── Tools.swift            # Tool definitions
│   └── ImageHandler.swift     # Base64 & temp file handling
└── README.md
```

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests (when implemented)
swift test
```

### Troubleshooting

#### "Command not found" error

Make sure you've built the project and the path in your Claude Code config matches the actual binary location.

#### "No text found" error

- Ensure the image contains clear, readable text
- Try using `"recognitionLevel": "accurate"` for better results
- Check that the language parameter matches the text in the image

#### Build errors

- Ensure you have Xcode 16+ or Swift 6.1+ installed
- Run `swift package resolve` to fetch dependencies

## How It Works

1. **Image Input**: Claude Code sends the image (as base64 or file path) to the MCP server
2. **Processing**: The server decodes base64 (if needed) and saves to a temporary file
3. **OCR**: Apple's Vision Framework processes the image using `VNRecognizeTextRequest`
4. **Extraction**: Text is extracted from the detected text observations
5. **Response**: Extracted text is returned to Claude Code
6. **Cleanup**: Temporary files are deleted

## Architecture

```
Claude Code → MCP Server → Apple Vision Framework
   │              │                  │
   │────image─────▶│                  │
   │              │────process──────▶│
   │              │                  │
   │◀────text─────│◀────results──────│
```

## Privacy

This server processes all images **locally on your Mac**. No data is sent to external servers. All processing is done using Apple's built-in Vision Framework.

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [Apple Vision Framework](https://developer.apple.com/documentation/vision)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)
