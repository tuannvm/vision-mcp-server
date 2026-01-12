import MCP
import Foundation
import Vision

/// MCP tool definitions for the OCR server.
enum OCRTools {

    /// Returns the tool definition for the OCR extraction tool.
    static var ocrExtractTextTool: Tool {
        Tool(
            name: "ocr_extract_text",
            description: """
            OCR - Extract text from images, screenshots, and photos using Apple Vision Framework. Fully offline, no data uploads.

            Use this tool when users ask to:
            - Extract text from an image, screenshot, or photo
            - OCR an image, read text from a picture
            - Transcribe text from a screenshot
            - Convert image text to digital format
            - Analyze text content in images

            Supported inputs: Base64 data URLs (pasted images), local file paths, remote http/https URLs
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "image": .object([
                        "type": .string("string"),
                        "description": .string("Image input in one of three formats: (1) Base64 data URL: data:image/xxx;base64,... - for pasted images, (2) Local file path: /path/to/image.jpg, (3) Remote URL: https://example.com/image.jpg")
                    ]),
                    "languages": .object([
                        "type": .string("array"),
                        "description": .string("Recognition languages (e.g., [\"en-US\", \"zh-Hans\"])"),
                        "items": .object([
                            "type": .string("string")
                        ])
                    ]),
                    "recognitionLevel": .object([
                        "type": .string("string"),
                        "description": .string("Recognition speed/accuracy tradeoff: fast or accurate"),
                        "enum": .array([.string("fast"), .string("accurate")])
                    ]),
                    "usesLanguageCorrection": .object([
                        "type": .string("boolean"),
                        "description": .string("Enable language model for better accuracy")
                    ])
                ]),
                "required": .array([.string("image")])
            ])
        )
    }

    /// Parameters extracted from the OCR tool call.
    struct OCRParameters: Sendable {
        let image: String
        let languages: [String]
        let recognitionLevel: String
        let usesLanguageCorrection: Bool

        /// Initializes parameters from a dictionary of arguments.
        /// - Parameter arguments: Tool arguments from the MCP call
        /// - Returns: Parsed parameters
        /// - Throws: If required parameters are missing or invalid
        static func from(_ arguments: [String: Any]) throws -> OCRParameters {
            guard let image = arguments["image"] as? String else {
                throw ToolError.missingParameter("image")
            }

            let languages = (arguments["languages"] as? [String]) ?? ["en-US"]
            let recognitionLevel = (arguments["recognitionLevel"] as? String) ?? "accurate"
            let usesLanguageCorrection = (arguments["usesLanguageCorrection"] as? Bool) ?? true

            return OCRParameters(
                image: image,
                languages: languages,
                recognitionLevel: recognitionLevel,
                usesLanguageCorrection: usesLanguageCorrection
            )
        }

        /// Converts the recognition level string to VNRequestTextRecognitionLevel.
        var vnRecognitionLevel: VNRequestTextRecognitionLevel {
            switch recognitionLevel.lowercased() {
            case "fast":
                return .fast
            case "accurate":
                return .accurate
            default:
                return .accurate
            }
        }
    }

    // MARK: - Errors

    enum ToolError: LocalizedError {
        case missingParameter(String)
        case invalidParameter(String, String)

        var errorDescription: String? {
            switch self {
            case .missingParameter(let param):
                return "Missing required parameter: \(param)"
            case .invalidParameter(let param, let message):
                return "Invalid parameter '\(param)': \(message)"
            }
        }
    }
}
