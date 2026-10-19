#!/usr/bin/env bash
# Pre-push guard for the PUBLIC str-dev repo. Install: ln -s ../../bin/public-push-guard.sh .git/hooks/pre-push
# Refuses the push (exit 1) when the pushed tree holds a path outside the allowlist, when any file or
# commit message contains a term from private/deny-patterns.txt, or when a pushed commit carries an
# author or committer address other than the GitHub no-reply one. Fails closed when the pattern file
# is missing or empty. Reads git's pre-push lines on stdin: <local ref> <local sha> <remote ref> <remote sha>.
set -uo pipefail

ALLOWED_EMAIL='979708+stratosjl@users.noreply.github.com'
ALLOWED_PATHS='^(\.gitignore|README\.md|CLAUDE\.md|bin/public-push-guard\.sh|cases/[A-Za-z0-9._-]+/(PKGBUILD|\.SRCINFO|README\.md))$'
ZERO='0000000000000000000000000000000000000000'

top=$(git rev-parse --show-toplevel) || exit 1
patterns_src="$top/private/deny-patterns.txt"
fail=0
say() { printf 'public-push-guard: %s\n' "$*" >&2; }

if [ ! -s "$patterns_src" ]; then
  say "REFUSED: $patterns_src is missing or empty, so nothing can be checked"
  exit 1
fi
patterns=$(mktemp); trap 'rm -f "$patterns"' EXIT
grep -vE '^\s*(#|$)' "$patterns_src" > "$patterns"
if [ ! -s "$patterns" ]; then
  say "REFUSED: $patterns_src holds no patterns"
  exit 1
fi

remote_name=${1:-}
checked=0
while read -r local_ref local_sha remote_ref remote_sha; do
  [ -n "${local_sha:-}" ] || continue
  if [ "$local_sha" = "$ZERO" ]; then
    say "REFUSED: deleting $remote_ref is a gated action; do it by hand after confirmation"
    fail=1; continue
  fi
  checked=$((checked + 1))

  # Walk every layer of an annotated tag (tags can wrap tags), checking each one, then require
  # that what is finally published is a commit: a tag on a tree or a blob is refused outright.
  obj=$local_sha
  while [ "$(git cat-file -t "$obj" 2>/dev/null)" = tag ]; do
    body=$(git cat-file tag "$obj")
    te=$(printf '%s\n' "$body" | sed -n 's/^tagger .*<\(.*\)> [0-9].*/\1/p' | head -1)
    if [ "$te" != "$ALLOWED_EMAIL" ]; then
      say "REFUSED: tag object ${obj:0:12} in $local_ref uses an address other than the no-reply one"; fail=1
    fi
    if printf '%s\n' "$body" | grep -q -i -F -f "$patterns"; then
      say "REFUSED: tag object ${obj:0:12} in $local_ref contains a deny-pattern term"; fail=1
    fi
    obj=$(printf '%s\n' "$body" | sed -n 's/^object //p' | head -1)
  done
  if [ "$(git cat-file -t "$obj" 2>/dev/null)" != commit ]; then
    say "REFUSED: $local_ref does not resolve to a commit"; fail=1; continue
  fi

  # Every commit being published, not only the tip: a file added and later deleted stays in history.
  if [ "$remote_sha" = "$ZERO" ]; then
    if [ -n "$remote_name" ]; then
      range=$(git rev-list "$obj" --not --remotes="$remote_name") || range=__error__
    else
      range=$(git rev-list "$obj") || range=__error__
    fi
  elif ! git cat-file -e "${remote_sha}^{commit}" 2>/dev/null; then
    say "REFUSED: the remote's $remote_ref is at ${remote_sha:0:12}, which this clone does not have; fetch first"
    fail=1; continue
  else
    range=$(git rev-list "$remote_sha..$obj") || range=__error__
  fi
  if [ "$range" = __error__ ]; then
    say "REFUSED: could not list the commits being pushed for $local_ref"; fail=1; continue
  fi

  for c in $range; do
    ae=$(git log -1 --format='%ae' "$c"); ce=$(git log -1 --format='%ce' "$c")
    if [ "$ae" != "$ALLOWED_EMAIL" ] || [ "$ce" != "$ALLOWED_EMAIL" ]; then
      say "REFUSED: commit ${c:0:12} uses an address other than the no-reply one"; fail=1
    fi
    if git log -1 --format='%B' "$c" | grep -q -i -F -f "$patterns"; then
      say "REFUSED: commit ${c:0:12} message contains a deny-pattern term"; fail=1
    fi
    bad_paths=$(git ls-tree -r --name-only "$c" | grep -vE "$ALLOWED_PATHS")
    if [ -n "$bad_paths" ]; then
      say "REFUSED: commit ${c:0:12} holds paths outside the allowlist:"; printf '  %s\n' $bad_paths >&2; fail=1
    fi
    hits=$(git grep -I -i -l -F -f "$patterns" "$c" --); grc=$?
    if [ "$grc" -gt 1 ]; then
      say "REFUSED: the content scan of commit ${c:0:12} failed (git grep exit $grc)"; fail=1
    elif [ -n "$hits" ]; then
      say "REFUSED: commit ${c:0:12} has deny-pattern terms in (terms not printed):"; printf '  %s\n' $hits >&2; fail=1
    fi
  done
done

[ "$fail" -eq 0 ] && say "OK: $checked ref(s) checked against $(wc -l < "$patterns") pattern(s)"
exit "$fail"
