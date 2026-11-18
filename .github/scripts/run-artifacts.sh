#!/usr/bin/env bash
# This run's artifacts of one name, downloaded and unzipped, oldest first.
#
#   run-artifacts.sh NAME DIR [MEMBER]
#
# Each artifact goes to DIR/<created_at>-<id>/, so the folders sort oldest first, and the script prints one folder name
# per line. With MEMBER, only the artifacts that hold that file are kept, and only that file is unzipped (the name
# junit-test-results-<bc version> is shared by every test app of the version). Expired artifacts are left out.
#
# A download that answers HTTP 404 is skipped: the artifact was deleted after the listing, by the merge job of another
# leg (bc-leg.yml deletes only its own leg's artifacts, so a leg never skips its own shard this way). Every other
# failure exits non-zero.
#
# Needs GH_TOKEN, GITHUB_REPOSITORY and GITHUB_RUN_ID (set in every GitHub job); GITHUB_API_URL defaults to github.com.
# Self-test: test-run-artifacts.py.
set -euo pipefail
name=$1 dir=$2 member=${3:-}
api=${GITHUB_API_URL:-https://api.github.com}
mkdir -p "$dir"
list=$(gh api --paginate "repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID/artifacts?per_page=100" \
  --jq ".artifacts[] | select(.name == \"$name\" and (.expired | not)) | \"\(.created_at)-\(.id) \(.id)\"" | sort)
while read -r folder id; do
  [ -n "$folder" ] || continue
  d="$dir/$folder"; mkdir -p "$d"
  # curl, not gh api: the HTTP status is needed. -L follows the redirect to the storage; curl does not send the token there.
  code=$(curl -sS -L -o "$d/a.zip" -w '%{http_code}' -H "Authorization: Bearer $GH_TOKEN" \
    -H 'Accept: application/vnd.github+json' "$api/repos/$GITHUB_REPOSITORY/actions/artifacts/$id/zip")
  if [ "$code" = 404 ]; then
    echo "artifact $id: HTTP 404, deleted after the listing by another leg; skipped" >&2; rm -rf "$d"; continue
  fi
  if [ "$code" != 200 ]; then echo "::error title=Artifacts::artifact $id ($name): download answered HTTP $code" >&2; exit 1; fi
  rc=0
  if [ -n "$member" ]; then unzip -o -q "$d/a.zip" "$member" -d "$d" 2>/dev/null || rc=$?
  else unzip -o -q "$d/a.zip" -d "$d" || rc=$?; fi
  rm -f "$d/a.zip"
  if [ -n "$member" ] && [ "$rc" = 11 ]; then rm -rf "$d"; continue; fi  # 11: no such file in the zip, another leg's
  if [ "$rc" != 0 ]; then echo "::error title=Artifacts::artifact $id ($name): unzip exited $rc" >&2; exit 1; fi
  echo "$folder"
done <<< "$list"
