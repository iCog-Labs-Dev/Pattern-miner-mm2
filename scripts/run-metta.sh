#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_MORK_BIN="$ROOT_DIR/../MORK/target/release/mork"

if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
  echo "Usage: scripts/run-metta.sh <case-file> [output-file]" >&2
  exit 2
fi

case_file="$1"
out_file="${2:-}"

if [[ "$case_file" != /* ]]; then
  case_file="$ROOT_DIR/$case_file"
fi

if [[ ! -f "$case_file" ]]; then
  echo "ERROR: missing file: $case_file" >&2
  exit 1
fi

if [[ -z "${MORK_BIN:-}" ]]; then
  if command -v mork >/dev/null 2>&1; then
    MORK_BIN="$(command -v mork)"
  else
    MORK_BIN="$DEFAULT_MORK_BIN"
  fi
fi

if [[ ! -x "$MORK_BIN" ]]; then
  echo "ERROR: mork binary not executable: $MORK_BIN" >&2
  echo "Set MORK_BIN=/path/to/mork and retry." >&2
  exit 1
fi

read_test_value() {
  local key="$1"
  local line
  line="$(grep -m 1 "^;; ${key} " "$case_file" || true)"
  printf '%s' "${line#;; ${key} }"
}

aux_args=()
while IFS= read -r aux_path || [[ -n "$aux_path" ]]; do
  [[ -z "$aux_path" ]] && continue
  if [[ "$aux_path" != /* ]]; then
    aux_path="$ROOT_DIR/$aux_path"
  fi
  aux_args+=("--aux-path" "$aux_path")
done < <(sed -n 's/^;; TEST-AUX[[:space:]]\{1,\}//p' "$case_file")

steps="$(read_test_value TEST-STEPS)"
steps="${steps:-100000}"

if [[ -n "$out_file" ]]; then
  "$MORK_BIN" run "$case_file" "$out_file" "${aux_args[@]}" --steps "$steps" --instrumentation 0
else
  "$MORK_BIN" run "$case_file" "${aux_args[@]}" --steps "$steps" --instrumentation 0
fi
