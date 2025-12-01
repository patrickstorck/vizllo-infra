#!/usr/bin/env bash
set -euo pipefail

STACK_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker-compose.yml"

usage() {
  echo "Usage: $(basename "$0") [frontend|backend|cloudflared|--all]"
  exit 1
}

TARGET="${1:---all}"

case "$TARGET" in
  frontend|backend|cloudflared)
    docker compose -f "$STACK_FILE" up -d "$TARGET"
    ;;
  --all|all)
    docker compose -f "$STACK_FILE" up -d
    ;;
  *)
    usage
    ;;
esac
