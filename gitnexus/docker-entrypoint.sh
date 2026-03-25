#!/bin/sh
set -eu

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
GITNEXUS_PORT="${GITNEXUS_PORT:-4747}"
GITNEXUS_HOST="${GITNEXUS_HOST:-0.0.0.0}"
AUTO_ANALYZE="${AUTO_ANALYZE:-true}"
ENABLE_EMBEDDINGS="${ENABLE_EMBEDDINGS:-false}"
GENERATE_SKILLS="${GENERATE_SKILLS:-false}"

if [ ! -d "$WORKSPACE_DIR" ]; then
  mkdir -p "$WORKSPACE_DIR"
fi

if [ "$AUTO_ANALYZE" = "true" ]; then
  set -- gitnexus analyze "$WORKSPACE_DIR"

  if [ ! -d "$WORKSPACE_DIR/.git" ]; then
    set -- "$@" --skip-git
  fi

  if [ "$ENABLE_EMBEDDINGS" = "true" ]; then
    set -- "$@" --embeddings
  fi

  if [ "$GENERATE_SKILLS" = "true" ]; then
    set -- "$@" --skills
  fi

  "$@"
fi

exec gitnexus serve --host "$GITNEXUS_HOST" --port "$GITNEXUS_PORT"
