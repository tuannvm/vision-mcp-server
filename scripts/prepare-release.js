#!/usr/bin/env node
/**
 * Release preparation script for @tuannvm/vision-mcp-server
 */

import { execSync } from 'child_process';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, '..');

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  cyan: '\x1b[36c'
};

function log(message, color = '') {
  console.log(`${color}${message}${colors.reset}`);
}

function logStep(step) {
  console.log(`\n${colors.bright}${colors.blue}━━━ ${step} ━━━${colors.reset}\n`);
}

function logSuccess(message) {
  log(`✅ ${message}`, colors.green);
}

function logError(message) {
  log(`❌ ${message}`, colors.red);
}

function exec(command, options = {}) {
  try {
    return execSync(command, {
      cwd: projectRoot,
      stdio: 'pipe',
      encoding: 'utf8',
      ...options
    }).trim();
  } catch (error) {
    if (options.allowFailure) {
      return null;
    }
    throw error;
  }
}

function checkGitStatus() {
  logStep('Git Status Checks');
  const gitStatus = exec('git status --porcelain');
  if (gitStatus) {
    logError('Uncommitted changes detected');
    return false;
  }
  logSuccess('No uncommitted changes');
  return true;
}

function checkBinary() {
  logStep('Binary Verification');
  const binaryPath = join(projectRoot, 'vision-mcp-server');
  if (!existsSync(binaryPath)) {
    logError('Binary not found. Run: npm run build:release');
    return false;
  }
  logSuccess('Binary found');
  return true;
}

async function main() {
  console.log(`\n${colors.bright}🚀 Vision MCP Server Release Preparation${colors.reset}\n`);
  
  const checks = [checkGitStatus, checkBinary];
  for (const check of checks) {
    if (!check()) {
      console.log(`\n${colors.red}❌ Checks failed!${colors.reset}\n`);
      process.exit(1);
    }
  }
  
  console.log(`\n${colors.green}✅ All checks passed!${colors.reset}\n`);
}

main().catch(error => {
  logError(`Error: ${error.message}`);
  process.exit(1);
});
