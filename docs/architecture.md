# Architecture

## Overview

The Vision MCP Server is a Swift-based MCP server that leverages Apple's Vision Framework for local OCR processing.

## Component Diagram

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│ Claude Code │────▶│ MCP Server   │────▶│ Vision Framework│
│             │     │ (Swift)      │     │ (VNRecognize..) │
└─────────────┘     └──────────────┘     └─────────────────┘
                          │
                          ▼
                    ┌──────────────┐
                    │ ImageHandler │
                    │ (Base64/File)│
                    └──────────────┘
```

## Module Structure

### main.swift
Entry point with `@MainActor` attribute. Sets up logging, creates the MCP server, configures tool handlers, and starts the stdio transport.

### VisionOCR.swift
Wrapper around Apple's `VNRecognizeTextRequest`. Key implementation details:

- `@MainActor` class for main-thread execution
- `withCheckedThrowingContinuation` to wrap synchronous Vision API
- `Task.detached` for CPU-bound OCR processing
- Returns `Sendable` types for Swift 6 concurrency

### MCPServer.swift
Sets up MCP protocol handlers:

- `ListTools` handler - returns tool definitions
- `CallTool` handler - dispatches to OCR processor
- Value-to-Any conversion for MCP protocol types

### Tools.swift
Defines the `ocr_extract_text` tool:

- JSON Schema for input validation
- `OCRParameters` struct for parsing arguments
- Converts recognition level string to `VNRequestTextRecognitionLevel`

### ImageHandler.swift
Handles image input from multiple formats:

- Parses base64 data URLs (`data:image/xxx;base64,...`)
- Validates local file paths
- Creates temporary files for Vision Framework
- Automatic cleanup of temp files

## Data Flow

1. **Request**: Claude Code sends `tools/call` with image (base64 or path)
2. **Parse**: `ImageHandler.processImageInput()` decodes base64 or validates file
3. **Process**: `VisionOCR.extractText()` runs `VNRecognizeTextRequest`
4. **Extract**: Text observations are concatenated with newlines
5. **Response**: `CallTool.Result` returns extracted text
6. **Cleanup**: Temp files deleted via `defer`

## Concurrency Model

```swift
@MainActor
func extractText(...) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
        Task.detached(priority: .userInitiated) {
            // Synchronous Vision API work here
            continuation.resume(returning: result)
        }
    }
}
```

This pattern:
- Keeps `@MainActor` context for the outer function
- Offloads CPU work to a detached task
- Bridges sync API to async/await

## MCP Tool Schema

```json
{
  "name": "ocr_extract_text",
  "description": "Extract text from image using local Apple Vision OCR",
  "inputSchema": {
    "type": "object",
    "properties": {
      "image": {"type": "string"},
      "languages": {"type": "array", "items": {"type": "string"}},
      "recognitionLevel": {"type": "string", "enum": ["fast", "accurate"]},
      "usesLanguageCorrection": {"type": "boolean"}
    },
    "required": ["image"]
  }
}
```

## Node.js Wrapper

The `vision-mcp.js` wrapper provides:

- Crash recovery with exponential backoff (max 5 restarts/60s)
- Clean shutdown on SIGINT/SIGTERM
- Auto-fix of executable permissions
- Separates stderr logging from stdout MCP protocol

## Error Handling

| Module | Errors |
|--------|--------|
| `VisionOCR` | `noTextFound`, `processingFailed` |
| `ImageHandler` | `invalidBase64Format`, `fileNotFound`, `tempFileCreationFailed` |
| `Tools` | `missingParameter`, `invalidParameter` |
| `MCPServer` | `unknownTool` |
