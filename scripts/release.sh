#!/usr/bin/env bash
# scripts/release.sh — local release helper.
#
# Syncs main, reads the version from project.godot (with an override prompt),
# creates an annotated tag, and pushes it. Pushing the tag triggers the
# Release workflow in .github/workflows/release.yml.
# Meant to be manually called for a release 
# Note the script is assumed to be running on linux

set -euo pipefail

# Config
REMOTE="origin"
MAIN_BRANCH="main"
PROJECT_FILE="project.godot"

# Helpers
die() {
    echo "error: $*" >&2
    exit 1
}

info() { echo "==> $*"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )" # its in a folder

cd "$PROJECT_ROOT"

# If project.godot isnt found the script probably as been moved without updating this one
[[ -f "$PROJECT_FILE" ]] || die "$PROJECT_FILE not found — is the script in scripts/?"

# If git config isnt set up terminate
git config user.email >/dev/null || die "git identity not configured (user.email)"
git config user.name  >/dev/null || die "git identity not configured (user.name)"

info "Checking working tree is clean"
STATUS=$(git status --porcelain) || die "git status failed"
[[ -z "$STATUS" ]] || die "working tree is dirty, commit or stash first"

info "Fetching $REMOTE"
git fetch "$REMOTE" --prune --tags

info "Checking out $MAIN_BRANCH"
git checkout "$MAIN_BRANCH"

info "Pulling latest $MAIN_BRANCH"
# Fails on any discrepancies with remote that are not possible to fast forward
git pull --ff-only "$REMOTE" "$MAIN_BRANCH"


# Reads config/version="x.y.z" from project.godot
info "Reading version from $PROJECT_FILE"
DETECTED=$(grep -oP 'config/version="\K[^"]+' "$PROJECT_FILE" || true)
[[ -n "$DETECTED" ]] || die "could not read version from $PROJECT_FILE"

VERSION="${DETECTED#v}" # Removes a leading v from the retrieved veriosn if present, so its just a x.y.z type
# Strictly x.y.z for now, no extra strings
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version format: $VERSION (expected x.y.z)"
TAG="v$VERSION" 

info "Version Found: [$DETECTED]"

# If the tag already exists exit
# The output of rev-parse should not be sent to output on regardless if it worked or not (noise)
if git rev-parse "refs/tags/$TAG" >/dev/null 2>&1; then
  die "tag $TAG already exists"
fi

# Confirm commit
echo
git --no-pager log -1 --oneline
echo
read -rp "Tag this commit as $TAG? [y/N] " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || die "aborted" # accept only Y or y

# Also ensure main itself is pushed (in case local was ahead)
info "Ensuring $MAIN_BRANCH is in sync with $REMOTE"
git push "$REMOTE" "$MAIN_BRANCH"

info "Creating annotated tag $TAG"
git tag -a "$TAG" -m "Release $TAG"

# Push (specific tag, not --tags)
info "Pushing $TAG to $REMOTE"
git push "$REMOTE" "$TAG"

info "Done. Tag $TAG pushed, release workflow should start."