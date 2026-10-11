# SkillSpector static pattern catalog (summary)

Condensed from the upstream SkillSpector scanner. The scanner reports 71 patterns across 17 categories. Rule IDs, severity names, and file locations are machine-readable — keep them untranslated in reports.

## Prompt injection (6)

| ID | Pattern | Severity |
|---|---|---|
| P1 | Instruction override (ignore safety constraints) | HIGH |
| P2 | Hidden instructions (comments, invisible text) | HIGH |
| P3 | Exfiltration commands (transmit context externally) | HIGH |
| P4 | Behavior manipulation (subtle decision steering) | MEDIUM |
| P5 | Harmful content (could cause physical harm) | CRITICAL |
| P9 | Whitespace padding (hiding instructions off-screen) | MEDIUM |

## Anti-refusal (3)

| ID | Pattern | Severity |
|---|---|---|
| AR1 | Refusal suppression ("never refuse", "always comply") | HIGH |
| AR2 | Disclaimer suppression ("no disclaimers", "do not moralize") | HIGH |
| AR3 | Safety-policy nullification (jailbreak framing) | HIGH |

## Data exfiltration (4)

| ID | Pattern | Severity |
|---|---|---|
| E1 | External transmission (data to external URLs) | MEDIUM |
| E2 | Env variable harvesting (collecting secrets) | HIGH |
| E3 | File system enumeration (scanning for sensitive files) | MEDIUM |
| E4 | Context leakage (conversation context sent externally) | HIGH |

## Privilege escalation (3)

| ID | Pattern | Severity |
|---|---|---|
| PE1 | Excessive permissions (beyond stated functionality) | LOW |
| PE2 | Sudo/root execution | MEDIUM |
| PE3 | Credential access (SSH keys, tokens, passwords) | HIGH |

## Supply chain (10)

| ID | Pattern | Severity |
|---|---|---|
| SC1 | Unpinned dependencies | LOW |
| SC2 | External script fetching (`curl \| bash`) | HIGH |
| SC3 | Obfuscated code (base64/hex execution) | HIGH |
| SC4 | Known vulnerable dependencies (live OSV.dev lookup) | HIGH |
| SC5 | Abandoned dependencies | MEDIUM |
| SC6 | Typosquatting | HIGH |
| SC8 | Shipped Python bytecode (`__pycache__` / `.pyc`) | HIGH |
| SC9 | Concealed executable artifact | HIGH |
| SC10 | Dependency source redirection | HIGH |

## Excessive agency (5)

| ID | Pattern | Severity |
|---|---|---|
| EA1 | Unrestricted tool access | HIGH |
| EA2 | Autonomous high-impact decisions without human-in-the-loop | HIGH |
| EA3 | Scope creep (beyond stated purpose) | MEDIUM |
| EA4 | Unbounded resource access (no rate limits/quotas) | MEDIUM |
| EA5 | External model/provider selection or coding-CLI shell-outs | MEDIUM/HIGH |

## Output handling (3)

| ID | Pattern | Severity |
|---|---|---|
| OH1 | Unvalidated output injection | HIGH |
| OH2 | Cross-context output without validation | MEDIUM |
| OH3 | Unbounded output | MEDIUM |

## System prompt leakage (3)

| ID | Pattern | Severity |
|---|---|---|
| P6 | Direct leakage (expose system prompts/rules) | HIGH |
| P7 | Indirect extraction (rephrase, translate, side-channels) | MEDIUM |
| P8 | Tool-based exfiltration (via file writes or network) | HIGH |

## Memory poisoning (3)

| ID | Pattern | Severity |
|---|---|---|
| MP1 | Persistent context injection | HIGH |
| MP2 | Context window stuffing | MEDIUM |
| MP3 | Memory/state tampering | HIGH |

## Tool misuse (3)

| ID | Pattern | Severity |
|---|---|---|
| TM1 | Tool parameter abuse (`shell=True`, `--force`) | HIGH |
| TM2 | Chaining abuse (bypass individual safety checks) | HIGH |
| TM3 | Unsafe defaults (disabled TLS, no auth) | MEDIUM |

## Rogue agent (2)

| ID | Pattern | Severity |
|---|---|---|
| RA1 | Self-modification (rewrite own code/config at runtime) | CRITICAL |
| RA2 | Session persistence (cron, startup scripts) | HIGH |

## Trigger abuse (3)

| ID | Pattern | Severity |
|---|---|---|
| TR1 | Overly broad trigger (matches common words) | MEDIUM |
| TR2 | Shadow command trigger (shadows built-ins or other skills) | HIGH |
| TR3 | Keyword baiting trigger (maximize activation) | MEDIUM |

## Behavioral AST (9)

| ID | Pattern | Severity |
|---|---|---|
| AST1 | `exec()` call | CRITICAL |
| AST2 | `eval()` call | HIGH |
| AST3 | Dynamic import (`__import__`) | HIGH |
| AST4 | `subprocess` call | HIGH |
| AST5 | `os.system` / exec-family | HIGH |
| AST6 | `compile()` call | MEDIUM |
| AST7 | Dynamic `getattr()` with non-literal names | MEDIUM |
| AST8 | Dangerous execution chain (exec/eval + network/encoded source) | CRITICAL |
| AST9 | Reflective `getattr()` sink (evades AST1/AST5) | HIGH |

## Taint tracking (5)

| ID | Pattern | Severity |
|---|---|---|
| TT1 | Direct taint flow (source to sink, no sanitization) | HIGH |
| TT2 | Variable-mediated taint flow | MEDIUM |
| TT3 | Credential exfiltration chain | CRITICAL |
| TT4 | File read to network exfiltration | HIGH |
| TT5 | External input to code execution | CRITICAL |

## YARA signatures (4)

| ID | Pattern | Severity |
|---|---|---|
| YR1 | Malware match | CRITICAL |
| YR2 | Webshell match | CRITICAL |
| YR3 | Cryptominer match | HIGH |
| YR4 | Hack tool / exploit match | HIGH |

## MCP least privilege (4)

| ID | Pattern | Severity |
|---|---|---|
| LP1 | Underdeclared capability (code uses unlisted permissions) | HIGH |
| LP2 | Wildcard permission (`*`, all, full, any) | MEDIUM |
| LP3 | Missing permission declaration with detectable capabilities | MEDIUM |
| LP4 | Overdeclared permission (declared, no matching code) | LOW |

## MCP tool poisoning (4)

| ID | Pattern | Severity |
|---|---|---|
| TP1 | Hidden instructions in metadata (comments, zero-width chars, base64, data URIs) | HIGH |
| TP2 | Unicode deception (homoglyphs, RTL overrides, mixed-script) | HIGH |
| TP3 | Parameter description injection | MEDIUM |
| TP4 | Description-behavior mismatch (LLM-powered) | MEDIUM |

## Risk scoring

- CRITICAL +50, HIGH +25, MEDIUM +10, LOW +5; executable scripts 1.3x multiplier; capped at 100.
- 0-20 LOW / SAFE · 21-50 MEDIUM / CAUTION · 51-80 HIGH / DO NOT INSTALL · 81-100 CRITICAL / DO NOT INSTALL.
