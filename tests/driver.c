/**
 * Types keystroke sequences through the si-ouc m17n input method and prints
 * the text each sequence leaves in the application.
 *
 * Usage: driver [--surrounding] < sequences
 *
 * Each input line is one sequence, typed into a fresh input context and an
 * empty application buffer.  Every character is one key, the two-character
 * escape `\b` is BackSpace and `\\` is a backslash.  One output line is
 * printed per input line.
 *
 * Keys are handled the way fcitx5-m17n's M17NState::handleKey does: the key
 * goes to minput_filter; when it is not filtered, minput_lookup returns the
 * produced text, which is committed, and a key the input method lets
 * through reaches the application, which inserts a printable key or deletes
 * the last character for BackSpace.  After the last key the remaining
 * preedit is appended, as an application does when focus leaves.
 *
 * With --surrounding the application buffer is offered to the input method
 * through the surrounding-text callbacks; without it the application
 * behaves like one that has no surrounding-text support.
 *
 * The input method is looked up through m17n's user database, so HOME must
 * contain .m17n.d/si-ouc.mim.
 */

#include <m17n.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/** Text committed to the application for the sequence being typed. */
static MText *app;

/** Prints MESSAGE to stderr and exits with status 2. */
static void die(const char *message) {
  fprintf(stderr, "driver: %s\n", message);
  exit(2);
}

/**
 * Answers the input method's surrounding-text requests from the application
 * buffer.  The cursor is always at the end of the buffer, so there is never
 * text after it.
 */
static void surrounding_text(MInputContext *ic, MSymbol command) {
  long len = (long)mplist_value(ic->plist);
  int app_len = mtext_len(app);

  if (command == Minput_get_surrounding_text) {
    int from = len < 0 ? app_len + (int)len : app_len;
    MText *text = mtext_duplicate(app, from < 0 ? 0 : from, app_len);

    mplist_set(ic->plist, Mtext, text);
    m17n_object_unref(text);
  } else if (command == Minput_delete_surrounding_text && len < 0) {
    int from = app_len + (int)len;

    mtext_del(app, from < 0 ? 0 : from, app_len);
  }
}

/**
 * Exits with an error unless m17n lists si-ouc as a sane input method, so a
 * keymap that m17n cannot load fails loudly instead of typing nothing.
 */
static void require_sane_input_method(void) {
  MPlist *list = minput_list(msymbol("si"));
  MPlist *p;
  int found = 0;

  for (p = list; mplist_key(p) != Mnil; p = mplist_next(p)) {
    MPlist *entry = mplist_value(p);
    MSymbol name = mplist_value(mplist_next(entry));
    MSymbol sane = mplist_value(mplist_next(mplist_next(entry)));

    if (name == msymbol("ouc")) {
      found = 1;
      if (sane != Mt)
        die("m17n lists si-ouc as not sane; check si-ouc.mim");
    }
  }
  m17n_object_unref(list);
  if (!found)
    die("si-ouc not found; HOME must contain .m17n.d/si-ouc.mim");
}

/** Sends KEY to the input context and applies the result to the app. */
static void press(MInputContext *ic, const char *key) {
  MSymbol symbol = msymbol(key);
  int thru = 0;

  if (!minput_filter(ic, symbol, NULL)) {
    MText *produced = mtext();

    thru = minput_lookup(ic, symbol, NULL, produced);
    mtext_cat(app, produced);
    m17n_object_unref(produced);
  }
  if (!thru)
    return;
  if (!strcmp(key, "BackSpace")) {
    int len = mtext_len(app);

    if (len > 0)
      mtext_del(app, len - 1, len);
  } else if (strlen(key) == 1) {
    mtext_cat_char(app, (unsigned char)key[0]);
  }
}

/** Types the keys of LINE into a fresh input context and prints the text. */
static void type_line(MInputMethod *im, const char *line) {
  MInputContext *ic = minput_create_ic(im, NULL);
  const char *c;

  if (!ic)
    die("cannot create an input context");
  app = mtext();
  for (c = line; *c; c++) {
    char key[2] = {*c, '\0'};

    if (*c != '\\') {
      press(ic, key);
    } else if (c[1] == 'b') {
      press(ic, "BackSpace");
      c++;
    } else if (c[1] == '\\') {
      press(ic, "\\");
      c++;
    } else {
      fprintf(stderr, "driver: bad escape in line: %s\n", line);
      exit(2);
    }
  }
  if (ic->preedit)
    mtext_cat(app, ic->preedit);
  if (mconv_encode_stream(Mcoding_utf_8, app, stdout) < 0)
    die("cannot encode output as UTF-8");
  putchar('\n');
  m17n_object_unref(app);
  minput_destroy_ic(ic);
}

int main(int argc, char **argv) {
  int surrounding = argc == 2 && !strcmp(argv[1], "--surrounding");
  MInputMethod *im;
  char *line = NULL;
  size_t cap = 0;
  ssize_t len;

  if (argc > 2 || (argc == 2 && !surrounding))
    die("usage: driver [--surrounding] < sequences");
  M17N_INIT();
  require_sane_input_method();
  im = minput_open_im(msymbol("si"), msymbol("ouc"), NULL);
  if (!im)
    die("m17n cannot open si-ouc");
  if (surrounding) {
    mplist_put(im->driver.callback_list, Minput_get_surrounding_text,
               (void *)surrounding_text);
    mplist_put(im->driver.callback_list, Minput_delete_surrounding_text,
               (void *)surrounding_text);
  }
  while ((len = getline(&line, &cap, stdin)) >= 0) {
    if (len > 0 && line[len - 1] == '\n')
      line[len - 1] = '\0';
    type_line(im, line);
  }
  free(line);
  minput_close_im(im);
  M17N_FINI();
  return 0;
}
