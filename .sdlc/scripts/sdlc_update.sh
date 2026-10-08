#!/usr/bin/env bash
# Install or upgrade the invariant layer from a tag of the template repo, and nothing else:
# the Makefile bodies, CLAUDE.md, flow.yaml, skills and deploy scripts are yours and are never
# touched. Files the new version drops are removed, so the standard can shrink as well as grow.
#
#   make sdlc-update                        the newest tag of the source in .sdlc/TEMPLATE_VERSION
#   ./.sdlc/scripts/sdlc_update.sh v1.2.0   a specific tag
#   ./.sdlc/scripts/sdlc_update.sh --source kayshn/poc-sdlc-template v1.0.0   first install
#
# Deliberately not run by `make install`: CI that overwrote the invariant layer before testing it
# could never detect drift, and one bad tag would break every consumer at once. Upgrading is an
# act with a diff and a review, which is the whole point.
set -euo pipefail
trap 'echo "sdlc_update.sh failed at line $LINENO" >&2' ERR
cd "$(dirname "$0")/../.."
# shellcheck source=.sdlc/scripts/_sdlc_lib.sh
. ./.sdlc/scripts/_sdlc_lib.sh

source_repo="" ref=""
while [ $# -gt 0 ]; do
  case $1 in
  --source)
    source_repo=${2:?--source needs owner/repo}
    shift 2
    ;;
  -*)
    echo "Unknown option: $1" >&2
    exit 2
    ;;
  *)
    ref=$1
    shift
    ;;
  esac
done

[ -n "$source_repo" ] || source_repo=$(template_source)
[ -n "$source_repo" ] || {
  echo "No template source: $VERSION_FILE is missing and --source was not given." >&2
  exit 1
}

if [ -z "$ref" ]; then
  ref=$(latest_tag "$source_repo")
  [ -n "$ref" ] || {
    echo "Could not read the tags of $source_repo." >&2
    exit 1
  }
fi

current=$(template_version)
if [ "$ref" = "$current" ]; then
  echo "Already on $source_repo $ref."
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo "Fetching $source_repo $ref"
curl -fsSL "https://codeload.github.com/$source_repo/tar.gz/refs/tags/$ref" | tar -xzf - -C "$tmp"
src=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)
[ -n "$src" ] || {
  echo "$source_repo $ref does not look like a template archive." >&2
  exit 1
}
[ -f "$src/$MANIFEST" ] || {
  echo "$source_repo $ref has no $MANIFEST, so its invariant layer is undefined." >&2
  exit 1
}

incoming=$(expand_invariant "$src")

# Drop invariant files this version no longer ships.
if [ -f "$MANIFEST" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    printf '%s\n' "$incoming" | grep -Fxq "$f" || {
      echo "  - $f"
      rm -f "$f"
    }
  done < <(awk '{print $2}' "$MANIFEST")
fi

while IFS= read -r f; do
  [ -n "$f" ] || continue
  mkdir -p "$(dirname "$f")"
  if [ -f "$f" ] && cmp -s "$src/$f" "$f"; then continue; fi
  cp -p "$src/$f" "$f"
  echo "  + $f"
done <<<"$incoming"

cp -p "$src/$MANIFEST" "$MANIFEST"

# Repoint the thin callers at the new tag. Needs a token allowed to touch .github/workflows/.
for wf in .github/workflows/*.yml; do
  [ -f "$wf" ] || continue
  grep -qE "uses: *$source_repo/\.github/workflows/_[a-z-]+\.yml@" "$wf" || continue
  sed -i.bak -E "s#(uses: *$source_repo/\.github/workflows/_[a-z-]+\.yml@)[^ ]*#\1$ref#" "$wf"
  rm -f "$wf.bak"
  echo "  ~ $wf -> $ref"
done

{
  echo "# Written by .sdlc/scripts/sdlc_update.sh. The invariant layer below this project's own"
  echo "# files came from the tag named here. Run \`make sdlc-update\` to move to a newer one."
  echo "source: $source_repo"
  echo "version: $ref"
  echo "installed: $(date -u +%Y-%m-%d)"
} >"$VERSION_FILE"

echo "Now on $source_repo $ref (was ${current:-nothing}). Verifying:"
verify_manifest "$MANIFEST" && echo "  ok   the invariant layer matches $ref"
