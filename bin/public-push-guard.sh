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

checked=0
while read -r local_ref local_sha remote_ref remote_sha; do
  [ -n "${local_sha:-}" ] || continue
  if [ "$local_sha" = "$ZERO" ]; then
    say "REFUSED: deleting $remote_ref is a gated action; do it by hand after confirmation"
    fail=1; continue
  fi
  checked=$((checked + 1))
  if [ "$remote_sha" = "$ZERO" ]; then
    range=$(git rev-list "$local_sha" --not --remotes=origin)
  else
    range=$(git rev-list "$remote_sha..$local_sha")
  fi

  bad_paths=$(git ls-tree -r --name-only "$local_sha" | grep -vE "$ALLOWED_PATHS")
  if [ -n "$bad_paths" ]; then
    say "REFUSED: paths outside the allowlist in $local_ref:"; printf '  %s\n' $bad_paths >&2; fail=1
  fi

  hits=$(git grep -I -i -l -F -f "$patterns" "$local_sha" -- 2>/dev/null)
  if [ -n "$hits" ]; then
    say "REFUSED: deny-pattern terms found in (terms not printed):"; printf '  %s\n' $hits >&2; fail=1
  fi

  for c in $range; do
    ae=$(git log -1 --format='%ae' "$c"); ce=$(git log -1 --format='%ce' "$c")
    if [ "$ae" != "$ALLOWED_EMAIL" ] || [ "$ce" != "$ALLOWED_EMAIL" ]; then
      say "REFUSED: commit ${c:0:12} uses an address other than the no-reply one"; fail=1
    fi
    if git log -1 --format='%B' "$c" | grep -q -i -F -f "$patterns"; then
      say "REFUSED: commit ${c:0:12} message contains a deny-pattern term"; fail=1
    fi
  done
done

[ "$fail" -eq 0 ] && say "OK: $checked ref(s) checked against $(wc -l < "$patterns") pattern(s)"
exit "$fail"
