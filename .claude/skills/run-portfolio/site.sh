#!/usr/bin/env bash
# Build, serve, and screenshot the portfolio site using podman containers,
# so no local Ruby or Chrome is needed.
#
#   site.sh build              one-off production-style build into _site/
#   site.sh serve              start jekyll serve in the background on $PORT
#   site.sh status | logs      is the preview up? / last log lines
#   site.sh shot PATH [OUT]    screenshot http://localhost:$PORT/PATH (serve first)
#   site.sh stop               stop the preview
#
# Env: PORT (default 4000), FETCH=0 to skip the GitHub API project fetch,
#      DEST (build output dir, default _site), SHOTS (default /tmp/portfolio-shots),
#      SIZE (default 1440,900).
set -euo pipefail

ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
NAME=portfolio-preview
PORT=${PORT:-4000}
FETCH=${FETCH:-1}
SHOTS=${SHOTS:-/tmp/portfolio-shots}
SIZE=${SIZE:-1440,900}
DEST=${DEST:-_site}
RUBY_IMAGE=docker.io/library/ruby:3.3
SHOT_IMAGE=localhost/portfolio-chromium

# Gems are cached in a named volume so only the first run pays for `bundle install`.
ruby_args=(-v "$ROOT":/site:Z -v portfolio-gems:/usr/local/bundle -w /site "$RUBY_IMAGE")
prelude="git config --global --add safe.directory /site && bundle install --quiet"
fetch_step="true"
[ "$FETCH" = 1 ] && fetch_step="ruby scripts/fetch_projects.rb"

running() { [ "$(podman ps --filter "name=^${NAME}$" --format '{{.Names}}')" = "$NAME" ]; }

case "${1:-}" in
  build)
    podman run --rm "${ruby_args[@]}" bash -c \
      "$prelude && $fetch_step && JEKYLL_ENV=production bundle exec jekyll build -d '$DEST'"
    ;;

  serve)
    if running; then echo "already running: http://localhost:$PORT/"; exit 0; fi
    podman rm -f "$NAME" >/dev/null 2>&1 || true
    podman run -d --name "$NAME" -p "$PORT":4000 "${ruby_args[@]}" bash -c \
      "$prelude && $fetch_step && bundle exec jekyll serve --host 0.0.0.0" >/dev/null
    for _ in $(seq 1 180); do
      logs=$(podman logs "$NAME" 2>&1 || true)
      if grep -q "Server running" <<<"$logs"; then echo "ready: http://localhost:$PORT/"; exit 0; fi
      if ! running; then echo "$logs" | tail -30; echo "serve FAILED (container exited)"; exit 1; fi
      sleep 1
    done
    echo "timed out waiting for jekyll; run: $0 logs"; exit 1
    ;;

  status)
    if running; then echo "running: http://localhost:$PORT/"; else echo "stopped"; exit 1; fi
    ;;

  logs)
    podman logs --tail "${2:-40}" "$NAME" 2>&1
    ;;

  shot)
    path=${2:-}; out=${3:-}
    running || { echo "preview not running; run: $0 serve"; exit 1; }
    if ! podman image exists "$SHOT_IMAGE"; then
      echo "building $SHOT_IMAGE (one time, ~1 min)..."
      podman build -q -t "$SHOT_IMAGE" -f - <<'IMG' >/dev/null
FROM docker.io/library/debian:bookworm-slim
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends chromium fonts-noto-core fonts-noto-mono ca-certificates >/dev/null && rm -rf /var/lib/apt/lists/*
IMG
    fi
    mkdir -p "$SHOTS"
    [ -n "$out" ] || out="$(echo "${path:-home}" | tr '/' '_' | sed 's/^_*//;s/_*$//').png"
    [ -n "$out" ] && [ "$out" != ".png" ] || out=home.png
    podman run --rm --network host -v "$SHOTS":/out:Z "$SHOT_IMAGE" \
      chromium --headless=new --no-sandbox --disable-gpu --hide-scrollbars \
      --window-size="$SIZE" --virtual-time-budget=3000 \
      --screenshot="/out/$out" "http://localhost:$PORT/${path#/}" 2>/dev/null
    echo "$SHOTS/$out"
    ;;

  stop)
    podman rm -f "$NAME" >/dev/null 2>&1 && echo stopped || echo "not running"
    ;;

  *)
    sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
