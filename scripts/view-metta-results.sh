#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-/tmp/hyperon-miner-mm2-results}"

if [[ "$#" -ne 2 ]]; then
  echo "Usage: scripts/view-metta-results.sh <case-file> <result-predicate>" >&2
  exit 2
fi

case_file="$1"
result_predicate="$2"

if [[ "$case_file" != /* ]]; then
  case_file="$ROOT_DIR/$case_file"
fi

if [[ ! -f "$case_file" ]]; then
  echo "ERROR: missing file: $case_file" >&2
  exit 1
fi

rel_case="${case_file#$ROOT_DIR/}"
safe_name="${rel_case//\//__}"
out_file="$OUT_DIR/${safe_name%.metta}.out.metta"

mkdir -p "$(dirname "$out_file")"

"$ROOT_DIR/scripts/run-metta.sh" "$case_file" "$out_file" >/dev/null

echo "Output: $out_file"
awk -v predicate="$result_predicate" 'index($0, "(" predicate " ") == 1' "$out_file"
