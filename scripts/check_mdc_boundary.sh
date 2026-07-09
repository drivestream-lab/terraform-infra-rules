#!/usr/bin/env bash
# Fail if MDC constitution files enumerate prayog skills (belong in AGENTS.md + prayog only).
set -euo pipefail

violations=0
for f in *.mdc; do
  [ -f "$f" ] || continue
  if grep -qE '^## Skills|^### Skills' "$f"; then
    echo "FAIL: skill catalog section in $f (use AGENTS.md + prayog-skills)"
    violations=1
  fi
  if grep -qE '`/[a-z][a-z0-9-]+`' "$f"; then
    echo "FAIL: slash-command skill reference in $f (constitution must not list prayog skills)"
    violations=1
  fi
done

if [ "$violations" -ne 0 ]; then
  exit 1
fi
echo "OK: MDC constitution boundary check passed"
