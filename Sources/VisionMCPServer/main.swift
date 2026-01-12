import Foundation
import MCP
import Logging

/// OCR MCP Server - Local-only text extraction from images using Apple Vision Framework.

// Run the server
let server = try await runOCRMCPServer()
exit(0)

/// Runs the OCR MCP server.
@MainActor
func runOCRMCPServer() async throws -> Server {
    // Configure logging to stderr (not stdout - stdout is for MCP protocol)
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardError(label: label)
        handler.logLevel = .debug
        return handler
    }
    let logger = Logger(label: "com.ocr-mcp-server")

    logger.info("Starting OCR MCP Server")

    // Create MCP server with capabilities
    let server = Server(
        name: "local-ocr",
        version: "1.0.0",
        capabilities: .init(
            tools: .init(listChanged: true)
        )
    )

    // Create Vision OCR handler
    let visionOCR = VisionOCR()

    // Configure server with tool handlers
    try await MCPServerSetup.configure(
        server: server,
        visionOCR: visionOCR,
        logger: logger
    )

    // Create stdio transport for communication with Claude Code
    let transport = StdioTransport(logger: logger)

    logger.info("Server configured, starting transport...")

    // Start the server
    try await server.start(transport: transport)

    logger.info("Server started and running")

    // Wait for server to finish (runs until EOF or error)
    await server.waitUntilCompleted()

    logger.info("Server stopped")

    return server
}
