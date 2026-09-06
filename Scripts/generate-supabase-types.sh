#!/bin/sh

set -eu

repository_root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
output_directory="$repository_root/CouplesTodo/Data/Remote/Generated"
output_file="$output_directory/DatabaseTypes.swift"
temporary_file="$(mktemp "${TMPDIR:-/tmp}/couples-todo-database-types.XXXXXX")"

cleanup() {
  rm -f "$temporary_file"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$output_directory"
supabase gen types \
  --local \
  --lang swift \
  --schema public \
  --swift-access-control internal \
  > "$temporary_file"
mv "$temporary_file" "$output_file"
trap - EXIT HUP INT TERM

echo "Generated $output_file"
