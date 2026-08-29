#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="${TEST_ROOT:-$ROOT_DIR/tests}"
OUT_DIR="${OUT_DIR:-/tmp/hyperon-miner-mm2-tests}"
DEFAULT_MORK_BIN="$ROOT_DIR/../MORK/target/release/mork"

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

mkdir -p "$OUT_DIR"

total=0
failures=0

read_test_value() {
  local case_file="$1"
  local key="$2"
  local line
  line="$(grep -m 1 "^;; ${key} " "$case_file" || true)"
  printf '%s' "${line#;; ${key} }"
}

append_aux_paths() {
  local case_file="$1"
  local aux_path

  while IFS= read -r aux_path || [[ -n "$aux_path" ]]; do
    [[ -z "$aux_path" ]] && continue
    if [[ "$aux_path" != /* ]]; then
      aux_path="$ROOT_DIR/$aux_path"
    fi
    aux_args+=("--aux-path" "$aux_path")
  done < <(sed -n 's/^;; TEST-AUX[[:space:]]\{1,\}//p' "$case_file")
}

expected_results() {
  local case_file="$1"
  sed -n 's/^[[:space:]]*(EXPECTED-RESULT[[:space:]]\{1,\}\([^[:space:])][^[:space:])]*\)[[:space:]]\{1,\}\(.*\))[[:space:]]*$/\1 \2/p' "$case_file"
}

run_case() {
  local case_file="$1"
  local rel_case
  local out_file
  local steps
  local expected_count=0
  local expected_entry
  local test_id
  local expected
  local aux_args=()

  if [[ "$case_file" != /* ]]; then
    case_file="$ROOT_DIR/$case_file"
  fi

  rel_case="${case_file#$TEST_ROOT/}"
  out_file="$OUT_DIR/${rel_case%.metta}.out.metta"

  total=$((total + 1))

  if [[ ! -f "$case_file" ]]; then
    echo "FAIL $rel_case"
    echo "  missing test file"
    failures=$((failures + 1))
    return
  fi

  steps="$(read_test_value "$case_file" TEST-STEPS)"
  steps="${steps:-100000}"
  append_aux_paths "$case_file"

  mkdir -p "$(dirname "$out_file")"

  echo "RUN  $rel_case"
  if ! "$MORK_BIN" run "$case_file" "$out_file" "${aux_args[@]}" --steps "$steps" --instrumentation 0 >/dev/null; then
    echo "FAIL $rel_case"
    echo "  mork run failed"
    failures=$((failures + 1))
    return
  fi

  while IFS= read -r expected_entry || [[ -n "$expected_entry" ]]; do
    expected_count=$((expected_count + 1))
    test_id="${expected_entry%% *}"
    expected="${expected_entry#* }"

    if ! grep -Fx -- "$expected" "$out_file" >/dev/null; then
      echo "FAIL $rel_case"
      echo "  missing expected fact for: $test_id"
      echo "  $expected"
      echo "  output: $out_file"
      failures=$((failures + 1))
      return
    fi
  done < <(expected_results "$case_file")

  if [[ "$expected_count" -eq 0 ]]; then
    echo "FAIL $rel_case"
    echo "  missing EXPECTED-RESULT fact"
    failures=$((failures + 1))
    return
  fi

  echo "PASS $rel_case"
}

if [[ "$#" -gt 0 ]]; then
  for case_file in "$@"; do
    run_case "$case_file"
  done
else
  while IFS= read -r case_file; do
    run_case "$case_file"
  done < <(find "$TEST_ROOT" -name "*-test.metta" | sort)
fi

echo
echo "Total: $total"
echo "Failed: $failures"

if [[ "$failures" -ne 0 ]]; then
  exit 1
fi
