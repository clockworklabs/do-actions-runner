#!/usr/bin/env bash
set -eEuo pipefail

if [ -z "${RUNNER_TOKEN:-}" ]
then
  echo "RUNNER_TOKEN is required"
  exit 1
fi

if [ -n "${ORG:-}" ]
then
  CONFIG_PATH=${ORG}
elif [ -n "${OWNER:-}" ] && [ -n "${REPO:-}" ]
then
  CONFIG_PATH=${OWNER}/${REPO}
else
  echo "[ORG] or [OWNER and REPO] is required"
  exit 1
fi

cleanup() {
  ./config.sh remove --token "${RUNNER_TOKEN}"
}

# run a dummy web server to pass health checks
while true; do 
  echo -e "HTTP/1.1 200 OK\n\n $(date)" | nc -l -p 8080 -q 1  > /dev/null 2>&1
done&

./config.sh \
  --url "https://github.com/${CONFIG_PATH}" \
  --token "${RUNNER_TOKEN}" \
  --name "${NAME:-$(hostname)}" \
  --unattended

trap 'cleanup' SIGTERM

./run.sh "$@" &

wait $!
