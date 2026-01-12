.PHONY: build build-release test clean install lint help

# Build the Swift binary in debug mode
build:
	swift build

# Build the Swift binary in release mode
build-release:
	swift build -c release
	@cp .build/release/VisionMCPServer ./vision-mcp-server
	@chmod +x ./vision-mcp-server

# Run Swift tests
test:
	swift test

# Clean build artifacts
clean:
	swift package clean

# Install dependencies
install:
	npm install

# Run linting (if swift-format is available)
lint:
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format --recursive --strict Sources/; \
	else \
		echo "swift-format not installed, skipping"; \
	fi

# Show help
help:
	@echo "Available targets:"
	@echo "  build         - Build Swift binary (debug)"
	@echo "  build-release - Build Swift binary (release)"
	@echo "  test          - Run Swift tests"
	@echo "  clean         - Clean build artifacts"
	@echo "  install       - Install npm dependencies"
	@echo "  lint          - Run swift-format linting"
	@echo "  help          - Show this help message"
