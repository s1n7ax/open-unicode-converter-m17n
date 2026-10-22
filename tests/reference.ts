/**
 * Types keystroke sequences through Open Unicode Converter's own Singlish
 * engine and prints the resulting text, one line per input line.
 *
 * Reads sequences from stdin in the format tests/driver.c reads: every
 * character is one key, `\b` is BackSpace and `\\` is a backslash.
 *
 * The engine is driven the way the web editor drives it, with the cursor
 * always at the end of the text: the current word is the text after the
 * last space or newline, each key goes to `convert(key, word)`, the rule's
 * `remove` characters are deleted and its `result` is appended, and
 * BackSpace deletes the last code point.  The web editor never inspects
 * the first character of the document when it looks for the start of the
 * word; that bug is not reproduced, so whitespace at the start of the text
 * ends the word like anywhere else.
 *
 * `open-unicode-converter` is resolved at bundle time to the source tree of
 * open-unicode-converter at commit 4b9bd62, e.g. with esbuild's `--alias`.
 */

import { readFileSync } from 'node:fs';
import SinglishConverterBuilder from 'open-unicode-converter/src/app/core/converters/singlish/singlish-converter-builder';

const converter = new SinglishConverterBuilder().get();

/** Splits a line into keys; BackSpace becomes the U+0008 character. */
function parseKeys(line: string): string[] {
  const keys: string[] = [];
  for (let i = 0; i < line.length; i++) {
    if (line[i] !== '\\') {
      keys.push(line[i]);
    } else if (line[i + 1] === 'b') {
      keys.push('\b');
      i++;
    } else if (line[i + 1] === '\\') {
      keys.push('\\');
      i++;
    } else {
      throw new Error(`bad escape in line: ${line}`);
    }
  }
  return keys;
}

/** Returns the text after the last space or newline in TEXT. */
function currentWord(text: string): string {
  const start = Math.max(text.lastIndexOf(' '), text.lastIndexOf('\n')) + 1;
  return text.substring(start);
}

/** Types KEYS into an empty text and returns the result. */
function type(keys: string[]): string {
  let text = '';
  for (const key of keys) {
    if (key === '\b') {
      text = Array.from(text).slice(0, -1).join('');
      continue;
    }
    const rule = converter.convert(key, currentWord(text));
    text = text.substring(0, text.length - rule.remove) + rule.result;
  }
  return text;
}

const lines = readFileSync(0, 'utf8').split('\n');
if (lines[lines.length - 1] === '') {
  lines.pop();
}
process.stdout.write(lines.map((line) => type(parseKeys(line)) + '\n').join(''));
