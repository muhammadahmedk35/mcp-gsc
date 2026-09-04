#!/bin/bash
# Decodes GSC_SERVICE_ACCOUNT_B64 (if present) into a service-account JSON key
# file for Google Search Console auth, for use in Claude Code cloud sessions.
#
# Security: this script never prints, logs, or persists the raw env var value
# or the decoded JSON contents anywhere other than the restricted output file.
set -euo pipefail

# Only run in Claude Code remote/cloud sessions.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Nothing to do if the credential isn't configured for this environment.
if [ -z "${GSC_SERVICE_ACCOUNT_B64:-}" ]; then
  exit 0
fi

OUTPUT_PATH="/tmp/gsc-service-account.json"
TMP_PATH="${OUTPUT_PATH}.tmp.$$"

# Restrict permissions on anything this script creates from here on.
umask 077

cleanup() {
  rm -f "$TMP_PATH"
}
trap cleanup EXIT

if ! printf '%s' "$GSC_SERVICE_ACCOUNT_B64" | base64 -d > "$TMP_PATH" 2>/dev/null; then
  echo "setup-gsc-credentials: GSC_SERVICE_ACCOUNT_B64 is not valid base64, skipping" >&2
  exit 0
fi

if ! python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$TMP_PATH" >/dev/null 2>&1; then
  echo "setup-gsc-credentials: decoded credential is not valid JSON, skipping" >&2
  exit 0
fi

mv "$TMP_PATH" "$OUTPUT_PATH"
chmod 600 "$OUTPUT_PATH"

echo "setup-gsc-credentials: wrote $OUTPUT_PATH"
