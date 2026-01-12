# Development Guide

## Prerequisites

```bash
# Install Swift 6.2+
# Via Xcode (recommended)
xcode-select --install

# Or via Swift package manager
# Download from https://swift.org/download/
```

## Project Structure

```
vision-mcp-server/
├── Package.swift              # Swift package manifest
├── Sources/VisionMCPServer/
│   ├── main.swift             # Entry point (@main)
│   ├── VisionOCR.swift        # Vision Framework wrapper
│   ├── MCPServer.swift        # MCP protocol handlers
│   ├── Tools.swift            # Tool definitions
│   └── ImageHandler.swift     # Base64 & temp file handling
├── vision-mcp.js              # Node.js wrapper
├── scripts/
│   ├── build-swift.sh         # Build script
│   └── prepare-release.js     # Release checks
└── package.json               # npm config
```

## Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Via npm (includes wrapper setup)
npm run build
npm run build:release
```

The build script copies the binary to `./vision-mcp-server` and makes it executable.

## Testing MCP Server

### Manual Testing

```bash
# Start server (will wait for stdin)
./vision-mcp-server

# In another terminal, send requests
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | ./vision-mcp-server
```

### Test with Python Script

```python
import json
import subprocess

result = subprocess.run(
    ["./vision-mcp-server"],
    input=json.dumps({
        "jsonrpc": "2.0",
        "method": "tools/list",
        "id": 1
    }),
    capture_output=True,
    text=True
)
print(result.stdout)
```

### Testing OCR

Create a test image and process it:

```bash
# Using the test script
python3 test_ocr.py
```

## Debugging

### Enable Verbose Logging

The server uses `swift-log` with debug level by default. Logs go to stderr (not stdout, which is reserved for MCP protocol).

```swift
// In main.swift
handler.logLevel = .debug  // Already set
```

### Common Issues

**"Command not found"**
- Verify binary path in Claude config
- Run `chmod +x vision-mcp-server`

**"No text found"**
- Check image has clear, readable text
- Try `"recognitionLevel": "accurate"`
- Verify language parameter matches image text

**Build errors**
- Ensure Swift 6.2+ (`swift --version`)
- Run `swift package resolve`

**Binary not executable**
```bash
chmod +x vision-mcp-server
```

## Adding New Languages

Edit `Tools.swift` to document new language codes, but Apple Vision Framework automatically supports all valid codes. No code changes needed.

Available codes: https://developer.apple.com/documentation/vision/vnrecognizetextrequest/3600635-recognitionlanguages

## Modifying Tool Schema

Edit `Tools.swift`:

```swift
static var ocrExtractTextTool: Tool {
    Tool(
        name: "ocr_extract_text",
        description: "...",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                // Add new properties here
            ]),
            "required": .array([...])
        ])
    )
}
```

Then update `OCRParameters.from()` to parse the new arguments.

## Publishing

```bash
# Run checks
npm run prepare-release

# Publish to npm
npm publish
```

The `prepare-release` script checks:
- Git status (no uncommitted changes)
- Binary exists at `./vision-mcp-server`

## Dependencies

```swift
// Package.swift
.package(
    url: "https://github.com/modelcontextprotocol/swift-sdk.git",
    from: "0.10.0"
)
```

To update dependencies:

```bash
swift package update
swift package resolve
```

## Swift 6 Concurrency Notes

This project uses Swift 6 strict concurrency:

- All public types are `@MainActor` or `Sendable`
- `Task.detached` for CPU-bound work
- `withCheckedThrowingContinuation` to bridge sync APIs
- No data races detected by Thread Sanitizer

Verify with:

```bash
swift build --sanitize=thread
```
