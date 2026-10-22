#!/usr/bin/env bash
#
# Differential tests for si-ouc.mim against Open Unicode Converter's engine.
#
# Usage: run.sh DRIVER REFERENCE_JS GENERATE_JS KEYMAP_HOME SPEC_TS
#
#   DRIVER       compiled tests/driver.c
#   REFERENCE_JS tests/reference.ts bundled for node
#   GENERATE_JS  tests/generate.ts bundled for node
#   KEYMAP_HOME  directory containing .m17n.d/si-ouc.mim, used as HOME
#   SPEC_TS      open-unicode-converter's singlish-converter.spec.ts
#
# Suites:
#   spec   every row of spec-cases.tsv, through the reference, the driver
#          with surrounding text and the driver without it, must give the
#          expected column; the rows must cite each expect( line of SPEC_TS
#          exactly once.
#   words  and corpus (words.txt and GENERATE_JS output): the driver with
#          surrounding text must equal the reference on every line, and the
#          driver without it on every line where BackSpace never follows a
#          space (looking back past committed text needs surrounding text).
#
# Prints the first 20 mismatches and the counts per suite; exits 1 on any
# mismatch.

set -euo pipefail

if [ $# -ne 5 ]; then
  echo "usage: $0 DRIVER REFERENCE_JS GENERATE_JS KEYMAP_HOME SPEC_TS" >&2
  exit 2
fi

driver=$1
reference=$2
generate=$3
export HOME=$4
spec=$5
tests=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

failed=0
shown=0

# compare SUITE MODE KEYS EXPECTED ACTUAL [skip-backspace-after-space]
compare() {
  local suite=$1 mode=$2 keys=$3 expected=$4 actual=$5 skip=${6:-}
  local result compared excluded mismatches
  result=$(paste "$keys" "$expected" "$actual" | awk -F '\t' \
    -v suite="$suite" -v mode="$mode" -v skip="$skip" -v shown="$shown" '
    function backspace_after_space(keys,    i, c, space) {
      space = 0
      for (i = 1; i <= length(keys); i++) {
        c = substr(keys, i, 1)
        if (c == " ") {
          space = 1
        } else if (c == "\\") {
          i++
          if (substr(keys, i, 1) == "b" && space) return 1
        }
      }
      return 0
    }
    {
      if (skip && backspace_after_space($1)) { excluded++; next }
      compared++
      if ($2 != $3) {
        mismatches++
        if (shown < 20) {
          shown++
          printf "MISMATCH %s/%s keys=[%s] expected=[%s] actual=[%s]\n", suite, mode, $1, $2, $3 > "/dev/stderr"
        }
      }
    }
    END { printf "%d %d %d %d\n", compared, excluded, mismatches, shown }')
  read -r compared excluded mismatches shown <<<"$result"
  if [ -n "$skip" ]; then
    echo "$suite/$mode: $compared compared, $excluded excluded (BackSpace after a space), $mismatches mismatches"
  else
    echo "$suite/$mode: $compared compared, $mismatches mismatches"
  fi
  if [ "$mismatches" -ne 0 ]; then
    failed=1
  fi
}

# type_all NAME KEYS: writes NAME.reference, NAME.surrounding, NAME.default
type_all() {
  local name=$1 keys=$2
  node "$reference" <"$keys" >"$work/$name.reference"
  "$driver" --surrounding <"$keys" >"$work/$name.surrounding"
  "$driver" <"$keys" >"$work/$name.default"
}

tail -n +2 "$tests/spec-cases.tsv" | cut -f1 >"$work/spec.keys"
tail -n +2 "$tests/spec-cases.tsv" | cut -f2 >"$work/spec.expected"
type_all spec "$work/spec.keys"
compare spec reference "$work/spec.keys" "$work/spec.expected" "$work/spec.reference" 2>&1
compare spec surrounding "$work/spec.keys" "$work/spec.expected" "$work/spec.surrounding" 2>&1
compare spec default "$work/spec.keys" "$work/spec.expected" "$work/spec.default" 2>&1

grep -n 'expect(' "$spec" | cut -d: -f1 | sort -n >"$work/spec.lines"
tail -n +2 "$tests/spec-cases.tsv" | cut -f3 | sort -n >"$work/spec.cited"
if cmp -s "$work/spec.lines" "$work/spec.cited"; then
  echo "spec/lines: $(wc -l <"$work/spec.lines") expect( lines, each cited once"
else
  echo "spec/lines: cited spec lines differ from the expect( lines (< spec, > cited):"
  diff "$work/spec.lines" "$work/spec.cited" || true
  failed=1
fi

cp "$tests/words.txt" "$work/words.keys"
node "$generate" >"$work/corpus.keys"
for suite in words corpus; do
  type_all "$suite" "$work/$suite.keys"
  compare "$suite" surrounding "$work/$suite.keys" "$work/$suite.reference" "$work/$suite.surrounding" 2>&1
  compare "$suite" default "$work/$suite.keys" "$work/$suite.reference" "$work/$suite.default" skip 2>&1
done

if [ "$failed" -ne 0 ]; then
  echo "FAILED"
  exit 1
fi
echo "PASSED"
