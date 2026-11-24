#!/bin/bash
# Backs up and restores public/system (files uploaded to the application).
#
# Usage:
#   scripts/backup_uploads.sh backup  [archive.tar.gz] [production|development|dev-domain]
#   scripts/backup_uploads.sh restore archive.tar.gz  [production|development|dev-domain]
#
# development: public/system is a directory of the project (bind mount).
# dev-domain:  public/system is a directory of the project (bind mount).
# production:  public/system is the "uploads" docker volume.
# If the environment is not given, it is detected from the running Compose project.
set -euo pipefail

usage() {
  echo "Usage: $0 backup [archive.tar.gz] [production|development|dev-domain]" >&2
  echo "       $0 restore <archive.tar.gz> [production|development|dev-domain]" >&2
  exit 1
}

ACTION="${1:-}"
ARCHIVE="${2:-}"
RAILS_ENV="${3:-}"

cd "$(dirname "$0")/.."

case "$ACTION" in
  backup) ARCHIVE="${ARCHIVE:-backup/uploads_$(date +%Y%m%d_%H%M%S).tar.gz}" ;;
  restore) [ -f "$ARCHIVE" ] || { echo "Archive not found: '${ARCHIVE}'" >&2; usage; } ;;
  *) usage ;;
esac

set -a
# shellcheck disable=SC1091
. ./.env
set +a

if [ -z "$RAILS_ENV" ]; then
  RUNNING_ENVS=()
  for candidate in production development dev-domain; do
    case "$candidate" in
      production) candidate_compose="docker-compose-prod.yml" ;;
      development) candidate_compose="docker-compose.yml" ;;
      dev-domain) candidate_compose="docker-compose-dev-domain.yml" ;;
    esac
    if [ -n "$(docker compose -f "$candidate_compose" ps --status running -q 2>/dev/null || true)" ]; then
      RUNNING_ENVS+=("$candidate")
    fi
  done

  if [ "${#RUNNING_ENVS[@]}" -gt 1 ]; then
    echo "Multiple Compose environments are running (${RUNNING_ENVS[*]}); specify one explicitly" >&2
    exit 1
  elif [ "${#RUNNING_ENVS[@]}" -eq 1 ]; then
    RAILS_ENV="${RUNNING_ENVS[0]}"
    echo "Detected running environment: $RAILS_ENV"
  else
    echo "Could not detect a running Compose project; using production" >&2
    RAILS_ENV=production
  fi
fi

case "$RAILS_ENV" in
  production) COMPOSE_FILE="docker-compose-prod.yml" ;;
  development) COMPOSE_FILE="docker-compose.yml" ;;
  dev-domain) COMPOSE_FILE="docker-compose-dev-domain.yml" ;;
  *) echo "Unsupported environment: $RAILS_ENV (use production, development, or dev-domain)" >&2; exit 1 ;;
esac

# Runs in a one-off app container so file ownership matches the application container.
in_system() {
  docker compose -f "$COMPOSE_FILE" run --rm --no-deps -T --entrypoint "$1" app "${@:2}"
}
SYSTEM_DIR=/code/public/system

backup_uploads() {
  in_system tar -czf - -C "$SYSTEM_DIR" . > "$1"
}

case "$ACTION" in
  backup)
    mkdir -p "$(dirname "$ARCHIVE")"
    printf "\n * Backing up %s (%s) to %s\n" "$SYSTEM_DIR" "$RAILS_ENV" "$ARCHIVE"
    backup_uploads "$ARCHIVE"
    ;;
  restore)
    printf '\nWARNING: Restoring will delete all current files in %s (%s).\n' "$SYSTEM_DIR" "$RAILS_ENV" >&2
    read -r -p 'Continue? [y/N] ' confirmation || confirmation=
    if [[ "$confirmation" != y && "$confirmation" != Y ]]; then
      echo "Restore cancelled." >&2
      exit 1
    fi

    printf "\n * Restoring %s (%s) from %s\n" "$SYSTEM_DIR" "$RAILS_ENV" "$ARCHIVE"
    gzip -t "$ARCHIVE"
    mkdir -p backup
    SAFETY_BACKUP="$(mktemp "backup/uploads_before_restore_$(date +%Y%m%d_%H%M%S)_XXXXXX.tar.gz")"
    printf '\n * Backing up current files to %s\n' "$SAFETY_BACKUP"
    if ! backup_uploads "$SAFETY_BACKUP"; then
      rm -f "$SAFETY_BACKUP"
      echo "Backup failed; restore cancelled." >&2
      exit 1
    fi
    in_system find "$SYSTEM_DIR" -mindepth 1 -delete
    in_system tar -xzf - -C "$SYSTEM_DIR" < "$ARCHIVE"
    ;;
esac

printf "\n * Done\n"