#!/usr/bin/env node

/**
 * Validates run-metadata.json written during full-audit setup.
 * Usage: node validate-run-metadata.cjs <path-to-run-metadata.json>
 *
 * Checks the setup facts required by references/full-audit-setup.md:
 * run_id, repo, target, source_ref, profile, scope_paths, budget,
 * execution_policy, and run_status. Candidate state lives in the
 * coverage ledger and findings.json, not here.
 */

const fs = require("node:fs");
const path = require("node:path");
const { TextDecoder } = require("node:util");

const LIMITS = Object.freeze({
  inputBytes: 1024 * 1024,
  nestingDepth: 32,
  validationErrors: 100,
});
const UTF8_DECODER = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true });
const VISIBLE_CONTENT = /[^\p{White_Space}\p{Cc}\p{Cf}\p{Default_Ignorable_Code_Point}]/u;
const UNSAFE_DIAGNOSTIC_CHARACTER = /[\p{Cc}\p{Cf}\p{Cs}\p{Zl}\p{Zp}\p{Default_Ignorable_Code_Point}]/gu;

class SafeInputError extends Error {}

function escapeUnsafeDiagnosticCharacters(value) {
  return String(value).replace(UNSAFE_DIAGNOSTIC_CHARACTER, (character) => {
    const codePoint = character.codePointAt(0);
    return codePoint <= 0xffff
      ? `\\u${codePoint.toString(16).padStart(4, "0")}`
      : `\\u{${codePoint.toString(16)}}`;
  });
}

function hasVisibleText(value) {
  return typeof value === "string" && value.trim() === value && VISIBLE_CONTENT.test(value);
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function validateDocument(meta) {
  const errors = [];
  const push = (message) => {
    if (errors.length < LIMITS.validationErrors) errors.push(escapeUnsafeDiagnosticCharacters(message));
  };
  if (!isObject(meta)) return ["$: expected a top-level object"];

  for (const field of ["run_id", "repo", "target", "source_ref"]) {
    if (!hasVisibleText(meta[field])) push(`$.${field}: expected non-empty text`);
  }
  if (!["quick", "standard", "deep"].includes(meta.profile)) {
    push("$.profile: expected one of quick, standard, deep");
  }
  if (!Array.isArray(meta.scope_paths)) {
    push("$.scope_paths: expected array");
  } else if (!meta.scope_paths.every((entry) => typeof entry === "string")) {
    push("$.scope_paths: expected an array of strings");
  }
  if (meta.budget !== null && !(typeof meta.budget === "number" && Number.isInteger(meta.budget) && meta.budget > 0)) {
    push("$.budget: expected null or a positive integer");
  }
  if (meta.execution_policy !== "sandboxed-source-and-local-only") {
    push('$.execution_policy: expected "sandboxed-source-and-local-only"');
  }
  if (!["in_progress", "complete", "incomplete"].includes(meta.run_status)) {
    push("$.run_status: expected one of in_progress, complete, incomplete");
  } else if (meta.run_status === "incomplete" && !hasVisibleText(meta.incomplete_reason)) {
    push("$.incomplete_reason: incomplete runs require a reason");
  }
  return errors;
}

function readFileWithinLimit(file) {
  const noFollow = fs.constants.O_NOFOLLOW;
  const nonBlock = fs.constants.O_NONBLOCK;
  if (!Number.isInteger(noFollow) || noFollow === 0 || !Number.isInteger(nonBlock) || nonBlock === 0) {
    throw new SafeInputError("OS no-follow and nonblocking input protection is unavailable");
  }
  let descriptor;
  try {
    descriptor = fs.openSync(file, fs.constants.O_RDONLY | noFollow | nonBlock);
  } catch (error) {
    if (error && (error.code === "ELOOP" || error.code === "EMLINK")) throw new SafeInputError("input must not be a symlink");
    throw error;
  }
  try {
    const stat = fs.fstatSync(descriptor);
    if (!stat.isFile()) throw new SafeInputError("input must be a regular file");
    if (stat.size > LIMITS.inputBytes) throw new SafeInputError(`input exceeds ${LIMITS.inputBytes} byte limit`);
    const chunks = [];
    const buffer = Buffer.allocUnsafe(64 * 1024);
    let bytesRead = 0;
    while (true) {
      const count = fs.readSync(descriptor, buffer, 0, buffer.length, null);
      if (count === 0) break;
      bytesRead += count;
      if (bytesRead > LIMITS.inputBytes) throw new SafeInputError(`input exceeds ${LIMITS.inputBytes} byte limit`);
      chunks.push(Buffer.from(buffer.subarray(0, count)));
    }
    try {
      return UTF8_DECODER.decode(Buffer.concat(chunks, bytesRead));
    } catch {
      throw new SafeInputError("input is not valid UTF-8");
    }
  } finally {
    fs.closeSync(descriptor);
  }
}

function run(file) {
  if (!file) {
    console.error("Usage: node validate-run-metadata.cjs <path-to-run-metadata.json>");
    return 1;
  }
  let contents;
  try {
    contents = readFileWithinLimit(file);
  } catch (error) {
    const reason = error instanceof SafeInputError ? error.message : "input could not be opened or read safely";
    console.error(`Failed to read run metadata: ${reason}`);
    return 1;
  }
  let meta;
  try {
    meta = JSON.parse(contents);
  } catch {
    console.error("Failed to parse run metadata: invalid JSON syntax");
    return 1;
  }
  const errors = validateDocument(meta);
  for (const message of errors) console.error("ERROR:", message);
  if (errors.length > 0) {
    console.error(`FAIL: ${errors.length} validation error(s)`);
    return 1;
  }
  console.log("PASS: run metadata valid");
  return 0;
}

module.exports = { LIMITS, validateDocument };

if (require.main === module) process.exit(run(process.argv[2]));
