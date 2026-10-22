/**
 * Prints the differential test corpus: keystroke sequences, one per line,
 * in the format tests/driver.c and tests/reference.ts read, without
 * duplicates.
 *
 * - every sequence of length 1 to 3 over the keys config.json maps, plus
 *   `c C S q 1 .`, space and BackSpace;
 * - every sequence of length 4 over `n d g k r u a A e h Y x`, space and
 *   BackSpace;
 * - every sequence of length 1 to 2 over the printable ASCII keys U+0021 to
 *   U+007E.
 *
 * `open-unicode-converter` is resolved at bundle time to the source tree of
 * open-unicode-converter at commit 4b9bd62, e.g. with esbuild's `--alias`.
 */

import config from 'open-unicode-converter/src/app/core/converters/singlish/config.json';

const BACKSPACE = '\\b';

/** Writes KEY in the line format, escaping a backslash key. */
function encode(key: string): string {
  return key === '\\' ? '\\\\' : key;
}

/** Returns every sequence of length MIN to MAX over KEYS, encoded. */
function sequences(keys: string[], min: number, max: number): string[] {
  const out: string[] = [];
  let level = [''];
  for (let length = 1; length <= max; length++) {
    level = level.flatMap((prefix) => keys.map((key) => prefix + key));
    if (length >= min) {
      out.push(...level);
    }
  }
  return out;
}

const mapped = Object.keys(config.mapping).map(encode);
const printable = Array.from({ length: 0x7e - 0x21 + 1 }, (_, i) =>
  encode(String.fromCharCode(0x21 + i)),
);

const corpus = new Set<string>([
  ...sequences([...mapped, 'c', 'C', 'S', 'q', '1', '.', ' ', BACKSPACE], 1, 3),
  ...sequences(['n', 'd', 'g', 'k', 'r', 'u', 'a', 'A', 'e', 'h', 'Y', 'x', ' ', BACKSPACE], 4, 4),
  ...sequences(printable, 1, 2),
]);

process.stdout.write([...corpus].map((line) => line + '\n').join(''));
