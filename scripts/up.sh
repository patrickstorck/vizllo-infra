#!/usr/bin/env bash
set -euo pipefail

STACK_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docker-compose.yml"
FRONTEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../frontend" && pwd)"
HOST_UID="${HOST_UID:-$(id -u)}"
HOST_GID="${HOST_GID:-$(id -g)}"
export HOST_UID HOST_GID

usage() {
  cat <<'EOF'
Usage: scripts/up.sh [options] [service]

Service (default: all):
  backend | frontend | cloudflared | all

Options:
  -d, --down         Stop and remove all running services before starting
  -b, --build        Rebuild images before starting
  -n, --no-cache     Rebuild without cache (implies --build and --down)
  -p, --pull         Pull latest base images (applies to build/up)
  -l, --logs         Follow logs after starting (default: true)
  --no-logs          Don't follow logs after starting
  -h, --help         Show this help message

Examples:
  scripts/up.sh                      # stop, rebuild and start all services with logs
  scripts/up.sh backend --build      # rebuild backend image and start it
  scripts/up.sh cloudflared --pull   # start tunnel without dependencies, pulling latest
  scripts/up.sh --no-cache           # rebuild everything from scratch and start
  scripts/up.sh --no-logs            # start without following logs
EOF
  exit 0
}

TARGET="all"
BUILD=true
NO_CACHE=false
PULL=false
DO_DOWN=true
FOLLOW_LOGS=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    backend|frontend|cloudflared|all|--all)
      TARGET="${1#--}"
      ;;
    -d|--down)
      DO_DOWN=true
      ;;
    -b|--build)
      BUILD=true
      ;;
    -n|--no-cache)
      NO_CACHE=true
      BUILD=true
      DO_DOWN=true
      ;;
    -p|--pull)
      PULL=true
      ;;
    -l|--logs)
      FOLLOW_LOGS=true
      ;;
    --no-logs)
      FOLLOW_LOGS=false
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

# Sempre derruba os containers primeiro para evitar problemas de cache
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔻 Derrubando containers existentes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose -f "$STACK_FILE" down --remove-orphans --volumes 2>/dev/null || true

# Limpa o cache do Next.js se necessário
if [[ "$DO_DOWN" == true || "$NO_CACHE" == true ]]; then
  if [[ -d "$FRONTEND_DIR/.next" ]]; then
    echo ""
    echo "🧹 Removendo cache do Next.js..."
    rm -rf "$FRONTEND_DIR/.next" 2>/dev/null || true
    if [[ -d "$FRONTEND_DIR/.next" ]]; then
      echo "   ⚠️  Permissões insuficientes, usando Docker para remover..."
      docker compose -f "$STACK_FILE" run --rm --user 0:0 --entrypoint sh frontend -lc "set -e; \
        chown -R $HOST_UID:$HOST_GID /app/.next || true; \
        rm -rf /app/.next || true; \
        mkdir -p /app/.next; \
        chown -R $HOST_UID:$HOST_GID /app/.next; \
        chmod -R 775 /app/.next" 2>/dev/null || true
    fi
  fi
fi

# Build com ou sem cache
if [[ "$NO_CACHE" == true ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔨 Rebuilding images (sem cache)..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  BUILD_CMD=(docker compose -f "$STACK_FILE" build --no-cache)
  [[ "$PULL" == true ]] && BUILD_CMD+=(--pull)
  BUILD_CMD+=("${SERVICE_ARGS[@]}")
  "${BUILD_CMD[@]}"
  BUILD=false
fi

# Inicia os containers com force-recreate para garantir que não há problemas
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Iniciando services: ${SERVICE_ARGS[*]:-all services}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
UP_CMD=(docker compose -f "$STACK_FILE" up -d --force-recreate)
[[ "$PULL" == true ]] && UP_CMD+=(--pull always)
[[ "$BUILD" == true ]] && UP_CMD+=(--build)
[[ "$TARGET" == "cloudflared" ]] && UP_CMD+=(--no-deps)
UP_CMD+=("${SERVICE_ARGS[@]}")
"${UP_CMD[@]}"

echo ""
echo "✅ Containers iniciados com sucesso!"

# Mostra os logs se solicitado
if [[ "$FOLLOW_LOGS" == true ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 Seguindo logs (Ctrl+C para sair)..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  sleep 1
  docker compose -f "$STACK_FILE" logs -f "${SERVICE_ARGS[@]}"
fi
