import Foundation
import MCP
import Logging

/// Sets up and configures the MCP server with OCR tool handlers.
@MainActor
enum MCPServerSetup {

    /// Configures the MCP server with all tool handlers.
    /// - Parameters:
    ///   - server: The MCP server instance
    ///   - visionOCR: The Vision OCR handler
    ///   - logger: Logger instance
    static func configure(
        server: Server,
        visionOCR: VisionOCR,
        logger: Logger
    ) async throws {
        // Register tools/list handler
        await server.withMethodHandler(ListTools.self) { _ in
            logger.info("Listing tools")
            return ListTools.Result(tools: [OCRTools.ocrExtractTextTool])
        }

        // Register tools/call handler
        await server.withMethodHandler(CallTool.self) { params in
            try await handleToolCall(
                name: params.name,
                arguments: params.arguments ?? [:],
                visionOCR: visionOCR,
                logger: logger
            )
        }
    }

    // MARK: - Tool Handlers

    private static func handleToolCall(
        name: String,
        arguments: [String: Value],
        visionOCR: VisionOCR,
        logger: Logger
    ) async throws -> CallTool.Result {
        logger.info("Tool call: \(name)")

        guard name == "ocr_extract_text" else {
            throw MCPServerError.unknownTool(name)
        }

        // Convert Value arguments to [String: Any] for parsing
        let argumentsDict = valueToDict(arguments)

        // Parse parameters
        let params = try OCRTools.OCRParameters.from(argumentsDict)

        // Process image input
        logger.debug("Processing image input")
        let imageURL = try await ImageHandler.processImageInput(params.image)

        // Ensure cleanup happens
        defer {
            ImageHandler.cleanup(imageURL)
        }

        // Perform OCR
        logger.debug("Starting OCR extraction")
        let text = try await visionOCR.extractText(
            from: imageURL.path,
            languages: params.languages,
            level: params.vnRecognitionLevel,
            correction: params.usesLanguageCorrection
        )

        logger.info("OCR extraction complete: \(text.count) characters")

        return CallTool.Result(
            content: [.text(text)],
            isError: false
        )
    }

    /// Converts MCP Value dictionary to [String: Any] for easier parsing.
    private static func valueToDict(_ valueDict: [String: Value]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in valueDict {
            result[key] = valueToAny(value)
        }
        return result
    }

    /// Converts MCP Value to Any.
    private static func valueToAny(_ value: Value) -> Any {
        switch value {
        case .null:
            return NSNull()
        case .bool(let b):
            return b
        case .int(let i):
            return i
        case .double(let d):
            return d
        case .string(let s):
            return s
        case .array(let a):
            return a.map { valueToAny($0) }
        case .object(let o):
            var dict: [String: Any] = [:]
            for (k, v) in o {
                dict[k] = valueToAny(v)
            }
            return dict
        case .data(let mimeType, let data):
            // For base64 data, return as base64 string
            if let mimeType = mimeType {
                return "data:\(mimeType);base64,\(data.base64EncodedString())"
            } else {
                return data.base64EncodedString()
            }
        }
    }

    // MARK: - Errors

    enum MCPServerError: LocalizedError {
        case unknownTool(String)

        var errorDescription: String? {
            switch self {
            case .unknownTool(let name):
                return "Unknown tool: \(name)"
            }
        }
    }
}
