#!/usr/bin/env bash
set -euo pipefail

STACK_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker-compose.yml"

usage() {
  cat <<'EOF'
Usage: scripts/up.sh [options] [service]

Service (default: all):
  backend | frontend | cloudflared | all

Options:
  -b, --build        Rebuild images before starting
  -n, --no-cache     Rebuild without cache (implies --build)
  -p, --pull         Pull latest base images (applies to build/up)
  -h, --help         Show this help message

Examples:
  scripts/up.sh                      # start all services
  scripts/up.sh backend --build      # rebuild backend image and start it
  scripts/up.sh cloudflared --pull   # start tunnel without dependencies, pulling latest
  scripts/up.sh --no-cache           # rebuild everything from scratch and start
EOF
  exit 0
}

TARGET="all"
BUILD=false
NO_CACHE=false
PULL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    backend|frontend|cloudflared|all|--all)
      TARGET="${1#--}"
      ;;
    -b|--build)
      BUILD=true
      ;;
    -n|--no-cache)
      NO_CACHE=true
      BUILD=true
      ;;
    -p|--pull)
      PULL=true
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option or service: $1"
      usage
      ;;
  esac
  shift
done

SERVICE_ARGS=()
if [[ "$TARGET" != "all" ]]; then
  SERVICE_ARGS+=("$TARGET")
fi

if [[ "$NO_CACHE" == true ]]; then
  BUILD_CMD=(docker compose -f "$STACK_FILE" build --no-cache)
  [[ "$PULL" == true ]] && BUILD_CMD+=(--pull)
  BUILD_CMD+=("${SERVICE_ARGS[@]}")
  echo "Building images (no cache) for: ${SERVICE_ARGS[*]:-all services}"
  "${BUILD_CMD[@]}"
  BUILD=false
fi

UP_CMD=(docker compose -f "$STACK_FILE" up -d)
[[ "$PULL" == true ]] && UP_CMD+=(--pull always)
[[ "$BUILD" == true ]] && UP_CMD+=(--build)
[[ "$TARGET" == "cloudflared" ]] && UP_CMD+=(--no-deps)
UP_CMD+=("${SERVICE_ARGS[@]}")

echo "Starting services: ${SERVICE_ARGS[*]:-all services}"
"${UP_CMD[@]}"
