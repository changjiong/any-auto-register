#!/bin/sh
set -eu

APP_DIR="/app"
RUNTIME_DIR="${APP_RUNTIME_DIR:-/runtime}"

mkdir -p "${RUNTIME_DIR}" "${RUNTIME_DIR}/logs" "${RUNTIME_DIR}/smstome_used"
touch \
  "${RUNTIME_DIR}/account_manager.db" \
  "${RUNTIME_DIR}/smstome_all_numbers.txt" \
  "${RUNTIME_DIR}/smstome_uk_deep_numbers.txt" \
  "${RUNTIME_DIR}/logs/solver.log"

ln -sfn "${RUNTIME_DIR}/account_manager.db" "${APP_DIR}/account_manager.db"
ln -sfn "${RUNTIME_DIR}/smstome_used" "${APP_DIR}/smstome_used"
ln -sfn "${RUNTIME_DIR}/smstome_all_numbers.txt" "${APP_DIR}/smstome_all_numbers.txt"
ln -sfn "${RUNTIME_DIR}/smstome_uk_deep_numbers.txt" "${APP_DIR}/smstome_uk_deep_numbers.txt"
ln -sfn "${RUNTIME_DIR}/logs/solver.log" "${APP_DIR}/services/turnstile_solver/solver.log"

echo "[entrypoint] Starting backend under Xvfb so Docker can handle both headed and headless browser tasks"

XVFB_DISPLAY="${DISPLAY:-:99}"
XAUTH_FILE="${RUNTIME_DIR}/.Xauthority"
touch "${XAUTH_FILE}"

# `xvfb-run` can hang indefinitely waiting for SIGUSR1 when used as PID 1 in
# containers. Start Xvfb directly so the API process always reaches its bind.
Xvfb "${XVFB_DISPLAY}" -screen 0 1920x1080x24 -nolisten tcp -auth "${XAUTH_FILE}" &
XVFB_PID=$!

cleanup() {
  if kill -0 "${XVFB_PID}" 2>/dev/null; then
    kill "${XVFB_PID}" 2>/dev/null || true
    wait "${XVFB_PID}" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

export DISPLAY="${XVFB_DISPLAY}"
export XAUTHORITY="${XAUTH_FILE}"

exec python main.py
