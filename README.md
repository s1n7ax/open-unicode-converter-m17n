# open-unicode-converter-m17n

`si-ouc` is a Sinhala Singlish input method for [m17n](https://www.nongnu.org/m17n/), so it works with fcitx5-m17n and ibus-m17n. It types exactly like the Singlish keymap of [Open Unicode Converter](https://github.com/s1n7ax/open-unicode-converter) ([sinhalaunicode.org](https://www.sinhalaunicode.org/)): the same keystrokes give the same Sinhala text, quirks included.

The keymap is written from scratch. Its rules are ported from Open Unicode Converter's [`config.json`](https://github.com/s1n7ax/open-unicode-converter/blob/4b9bd6282311168016020326f52861fb117cfd80/src/app/core/converters/singlish/config.json) at commit `4b9bd62`, and the tests check it against that converter's own engine.

## Install

### fcitx5 or ibus

1. Copy `si-ouc.mim` to `~/.m17n.d/` (create the directory if it does not exist).
2. Restart the input method framework: `fcitx5 -r`, or `ibus restart`.
3. Add the input method `si-ouc`. fcitx5 lists it as `m17n_si_ouc`; ibus lists it as `m17n:si:ouc`.

### Nix flake

The flake's `packages.<system>.default` (for `x86_64-linux` and `aarch64-linux`) installs the keymap to `share/m17n/si-ouc.mim`.

```nix
# flake.nix
{
  inputs.open-unicode-converter-m17n = {
    url = "github:s1n7ax/open-unicode-converter-m17n";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Install it into `~/.m17n.d` with home-manager, then add `m17n_si_ouc` to your fcitx5 input group:

```nix
{ inputs, pkgs, ... }:
let
  keymap = inputs.open-unicode-converter-m17n.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.file.".m17n.d/si-ouc.mim".source = "${keymap}/share/m17n/si-ouc.mim";
}
```

## How it types

The word you are typing stays underlined in the preedit, where later keys can change it (`k` gives ක්, then `a` turns it into ක). Space, Return, Tab, the arrows and shortcuts commit the word and then do their usual job. Backspace deletes the last character of the word; once the word is empty it deletes text the application already has.

Rules look at the text right before the cursor: the preedit first, then the application's text, where the application shares it (surrounding text).

## Keymap

Every key types its default text unless one of its rules matches the end of the current word. A key's rules are tried in the order listed and the first match wins. "Consonant" means one of these 40 letters: ක ඛ ග ඝ ඞ ඟ ච ඡ ජ ඣ ඤ ඦ ට ඨ ඩ ඪ ණ ඬ ත ථ ද ධ න ඳ ප ඵ බ භ ම ඹ ය ර ල ව ශ ෂ ස හ ළ ෆ (ඥ is not one of them).

### Vowels

| Key | Default | Rules (word ends with → becomes) | Examples |
| --- | --- | --- | --- |
| `a` | අ | අ → ආ<br>ඇ → ඈ<br>එ → ඒ<br>් → (removed)<br>consonant → adds ා<br>ැ → ෑ<br>ෙ → ේ<br>ො → ෝ | `a` අ, `aa` ආ, `Aa` ඈ, `ea` ඒ, `ka` ක, `kaa` කා, `kAa` කෑ, `kea` කේ, `koa` කෝ |
| `A` | ඇ | ් → ැ | `A` ඇ, `kA` කැ |
| `e` | එ | අ → ඈ<br>ඉ → ඊ<br>ඔ → ඕ<br>් → ෙ<br>ැ → ෑ<br>consonant → adds ෑ<br>ො → ෝ<br>ි → ී<br>ෙ → ී | `e` එ, `ae` ඈ, `ie` ඊ, `oe` ඕ, `ke` කෙ, `kAe` කෑ, `kae` කෑ, `koe` කෝ, `kie` කී, `kee` කී |
| `i` | ඉ | ඉ → ඊ<br>් → ි<br>ි → ී | `i` ඉ, `ii` ඊ, `ki` කි, `kii` කී |
| `I` | I | ් → ෛ | `I` I, `kI` කෛ |
| `u` | උ | උ → ඌ<br>අ → ඖ<br>්‍ර් → ෘ<br>් → ු<br>ු → ූ<br>ෘ → ෲ<br>consonant → adds ෞ | `u` උ, `uu` ඌ, `au` ඖ, `kru` කෘ, `ku` කු, `kuu` කූ, `kruu` කෲ, `kau` කෞ |
| `U` | U | ් → ෞ | `U` U, `kU` කෞ |
| `o` | ඔ | ් → ො | `o` ඔ, `ko` කො |

### Consonants

| Key | Default | Rules (word ends with → becomes) | Examples |
| --- | --- | --- | --- |
| `k` | ක් | | `k` ක් |
| `K` | ඛ් | | `K` ඛ් |
| `g` | ග් | න්න් → ඟ් | `g` ග්, `nng` ඟ් |
| `G` | ඝ් | | `G` ඝ් |
| `j` | ජ් | | `j` ජ් |
| `J` | ඣ් | | `J` ඣ් |
| `N` | ණ් | ඛ් → ඤ් | `N` ණ්, `KN` ඤ්, `khN` ඤ් |
| `t` | ට් | | `t` ට් |
| `T` | ඨ් | | `T` ඨ් |
| `d` | ඩ් | න්න් → ඬ් | `d` ඩ්, `nnd` ඬ් |
| `D` | ඪ් | | `D` ඪ් |
| `n` | න් | | `n` න් |
| `p` | ප් | | `p` ප් |
| `P` | ඵ් | | `P` ඵ් |
| `b` | බ් | | `b` බ් |
| `B` | ඹ් | | `B` ඹ් |
| `m` | ම් | | `m` ම් |
| `y` | ය් | | `y` ය් |
| `Y` | Y | ් → ්‍ය් (with a zero-width joiner) | `Y` Y, `kY` ක්‍ය් |
| `r` | ර් | ් → ්‍ර් (with a zero-width joiner) | `r` ර්, `kr` ක්‍ර් |
| `l` | ල් | | `l` ල් |
| `w` | ව් | | `w` ව් |
| `v` | ව් | | `v` ව් |
| `L` | ළ් | | `L` ළ් |
| `s` | ස් | | `s` ස් |
| `f` | ෆ් | | `f` ෆ් |
| `h` | හ් | ක් → ඛ්<br>ග් → ඝ්<br>c → ච්<br>C → ඡ්<br>ට් → ත්<br>ඨ් → ථ්<br>ඩ් → ද්<br>ඪ් → ධ්<br>ඬ් → ඳ්<br>ප් → ඵ්<br>බ් → භ්<br>ස් → ශ්<br>S → ෂ් | `h` හ්, `kh` ඛ්, `gh` ඝ්, `ch` ච්, `Ch` ඡ්, `th` ත්, `Th` ථ්, `dh` ද්, `Dh` ධ්, `nndh` ඳ්, `ph` ඵ්, `bh` භ්, `sh` ශ්, `Sh` ෂ් |

### Signs

| Key | Default | Rules (word ends with → becomes) | Examples |
| --- | --- | --- | --- |
| `x` | අං | ් → ං<br>any other character → adds ං | `x` අං, `kx` කං, `kax` කං, `1x` 1ං |
| `X` | අඃ | ් → ඃ<br>any other character → adds ඃ | `X` අඃ, `kX` කඃ, `kaX` කඃ |

### Everything else

Every other printable key (`c`, `C`, `S`, `q`, `z`, digits, punctuation, …) types itself into the word, as on the web. That is how `c`, `C` and `S` followed by `h` give ච්, ඡ් and ෂ්.

## Known differences

- On the web, a space or newline typed at the very start of the document counts as part of the first word, because the web editor never looks at the first character when it searches for the start of a word. So at the start of a document ` x` gives ` ං` on the web and ` අං` here, and Return then `x` gives a newline then ං on the web and a newline then අං here. Everywhere else a space or newline ends the word on both.
- Rules that need text from before a word you already committed (for example after Space and then Backspace) read it from the application. Applications without surrounding-text support, such as many terminals, cannot provide it, so there the next key starts a new word: `ka`, Space, Backspace, `x` gives කං on the web and in applications with surrounding text, and කඅං in applications without it.

## Tests

```sh
nix flake check
```

The check builds `tests/driver.c` against m17n-lib, bundles Open Unicode Converter's own engine from the pinned source with `tests/reference.ts`, and runs `tests/run.sh`:

- **spec**: every assertion of the converter's `singlish-converter.spec.ts` (`tests/spec-cases.tsv`), typed through the reference engine and through the keymap with and without surrounding text.
- **words**: real words and sentences from `tests/words.txt`, compared with the reference engine.
- **corpus**: about 139,000 key sequences from `tests/generate.ts`, compared with the reference engine.

`nix develop` gives a shell with the same tools.

## License

[MIT](LICENSE)
