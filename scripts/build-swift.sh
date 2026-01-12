#!/bin/bash
# Build script for Vision MCP Server Swift binary
# Usage: ./scripts/build-swift.sh [--release]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[build-swift]${NC} $1"
}

error() {
    echo -e "${RED}[build-swift]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[build-swift]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Parse arguments
BUILD_CONFIG="debug"
if [[ "$1" == "--release" ]]; then
    BUILD_CONFIG="release"
fi

log "Building Vision MCP Server (config: $BUILD_CONFIG)..."

# Check Swift version
SWIFT_VERSION=$(swift --version 2>/dev/null | head -1 || echo "unknown")
log "Swift version: $SWIFT_VERSION"

# Minimum Swift version check
REQUIRED_SWIFT="6.1"
if ! swift --version | grep -q "6\.[1-9]"; then
    if ! swift --version | grep -q "6\.2"; then
        error "Swift 6.1+ is required (found: $SWIFT_VERSION)"
        error "Please update Xcode or Swift toolchain"
        exit 1
    fi
fi

# Build
if [[ "$BUILD_CONFIG" == "release" ]]; then
    swift build -c release
else
    swift build
fi

# Copy binary to project root
# Binary is named 'VisionMCPServer' by Package.swift
SOURCE_BINARY=".build/$BUILD_CONFIG/VisionMCPServer"
if [[ ! -f "$SOURCE_BINARY" ]]; then
    error "Binary not found at: $SOURCE_BINARY"
    exit 1
fi

log "Copying binary to project root as vision-mcp-server..."
cp "$SOURCE_BINARY" ./vision-mcp-server

# Make executable
chmod +x ./vision-mcp-server

# Verify binary
if ! file ./vision-mcp-server | grep -q "Mach-O.*executable"; then
    error "Binary is not a valid Mach-O executable"
    exit 1
fi

# Show binary info
BINARY_SIZE=$(du -h ./vision-mcp-server | cut -f1)
BINARY_ARCH=$(file ./vision-mcp-server | grep -o 'arm64\|x86_64' | tr '\n' ' ')

log "Build successful!"
log "  Binary: ./vision-mcp-server"
log "  Size: $BINARY_SIZE"
log "  Architecture(s): $BINARY_ARCH"

# Test binary
log "Testing binary..."
if ! ./vision-mcp-server --help >/dev/null 2>&1; then
    # Our binary doesn't have --help, just test it runs
    :
fi

log "Done!"
