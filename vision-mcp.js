#!/usr/bin/env node
/**
 * Vision MCP Server wrapper
 *
 * This Node.js wrapper spawns the Swift binary and provides:
 * - Crash recovery with exponential backoff
 * - Clean shutdown on SIGINT/SIGTERM
 * - Error handling and logging
 */

import { spawn, execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Binary path relative to this script
// Note: The actual binary is named 'vision-mcp-server' (copied from ocr-mcp-server)
const binaryPath = join(__dirname, 'vision-mcp-server');

// Configuration
const MAX_RESTARTS = 5;
const RESTART_WINDOW_MS = 60000;
const INITIAL_DELAY_MS = 1000;
const MAX_DELAY_MS = 30000;

class VisionMCPWrapper {
  constructor() {
    this.restartTimestamps = [];
    this.delay = INITIAL_DELAY_MS;
    this.child = null;
    this.shuttingDown = false;
  }

  start() {
    // Check if binary exists
    if (!existsSync(binaryPath)) {
      console.error('[Vision MCP] Binary not found at:', binaryPath);
      console.error('[Vision MCP] Please run: npm run build:release');
      process.exit(1);
    }

    // Check restart rate limiting
    const now = Date.now();
    this.restartTimestamps = this.restartTimestamps.filter(
      ts => now - ts < RESTART_WINDOW_MS
    );

    if (this.restartTimestamps.length >= MAX_RESTARTS) {
      console.error(`[Vision MCP] Too many restarts (${MAX_RESTARTS} in ${RESTART_WINDOW_MS}ms)`);
      process.exit(1);
    }

    console.error('[Vision MCP] Starting server...');
    this.child = spawn(binaryPath, [], {
      stdio: 'inherit',
      env: {
        ...process.env,
        VISION_MCP_WRAPPER: 'true'
      }
    });

    this.child.on('exit', (code, signal) => {
      if (this.shuttingDown) return process.exit(code || 0);

      if (code === 0 || signal === 'SIGINT' || signal === 'SIGTERM') {
        console.error('[Vision MCP] Server exited cleanly');
        process.exit(code || 0);
      }

      this.handleCrash(code, signal);
    });

    this.child.on('error', (err) => {
      console.error('[Vision MCP] Failed to launch:', err.message);

      // Handle permission errors
      if (err.code === 'EACCES') {
        try {
          execSync(`chmod +x "${binaryPath}"`);
          console.error('[Vision MCP] Fixed executable bit, retrying...');
          this.handleCrash(1);
          return;
        } catch (_) {
          console.error('[Vision MCP] Could not make binary executable');
        }
      }

      this.handleCrash(err.code || 1);
    });
  }

  handleCrash(code, signal) {
    const signalStr = signal ? `, signal ${signal}` : '';
    console.error(`[Vision MCP] Server crashed (code ${code}${signalStr})`);

    this.restartTimestamps.push(Date.now());

    setTimeout(() => {
      this.delay = Math.min(this.delay * 2, MAX_DELAY_MS);
      this.start();
    }, this.delay);
  }

  shutdown() {
    this.shuttingDown = true;
    if (this.child && !this.child.killed) {
      console.error('[Vision MCP] Shutting down...');
      this.child.kill('SIGTERM');
    }
  }
}

// Create and start wrapper
const wrapper = new VisionMCPWrapper();
wrapper.start();

// Signal handlers
process.on('SIGINT', () => {
  console.error('\n[Vision MCP] SIGINT received, shutting down...');
  wrapper.shutdown();
});

process.on('SIGTERM', () => {
  console.error('[Vision MCP] SIGTERM received, shutting down...');
  wrapper.shutdown();
});

process.on('uncaughtException', (err) => {
  console.error('[Vision MCP] Uncaught exception:', err);
  wrapper.shutdown();
});

process.on('unhandledRejection', (reason) => {
  console.error('[Vision MCP] Unhandled rejection:', reason);
  wrapper.shutdown();
});
