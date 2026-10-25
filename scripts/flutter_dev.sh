#!/bin/sh
# Local debug builds with quiz configuration; never prints the credential.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"

if [ ! -s dev-secrets.json ]; then
  printf '%s\n' 'Add a valid OPENAI_API_KEY to local dev-secrets.json first. See README.md.' >&2
  exit 1
fi

action=${1:-run}
if [ "$#" -gt 0 ]; then shift; fi
for argument in "$@"; do
  case "$argument" in
    --release|--profile)
      printf '%s\n' 'This launcher is for local debug builds only.' >&2
      exit 1
      ;;
  esac
done
case "$action" in
  run)
    exec flutter run --debug --dart-define-from-file="$project_dir/dev-secrets.json" "$@"
    ;;
  apk)
    exec flutter build apk --debug --dart-define-from-file="$project_dir/dev-secrets.json" "$@"
    ;;
  *)
    printf '%s\n' 'Usage: sh scripts/flutter_dev.sh [run|apk] [Flutter options]' >&2
    exit 1
    ;;
esac
