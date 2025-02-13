#!/usr/bin/env bash
set -eEuo pipefail

if [ -z "${TOKEN:-}" ]
then
  echo "TOKEN is required"
  exit 1
fi

if [ -n "${ORG:-}" ]
then
  API_PATH=orgs/${ORG}
  CONFIG_PATH=${ORG}
elif [ -n "${OWNER:-}" ] && [ -n "${REPO:-}" ]
then
  API_PATH=repos/${OWNER}/${REPO}
  CONFIG_PATH=${OWNER}/${REPO}
else
  echo "[ORG] or [OWNER and REPO] is required"
  exit 1
fi

RUNNER_TOKEN=$(curl -s -X POST -H "authorization: token ${TOKEN}" "https://api.github.com/${API_PATH}/actions/runners/registration-token" | jq -r .token)

cleanup() {
  ./config.sh remove --token "${RUNNER_TOKEN}"
}

# run a dummy web server to pass health checks
while true; do 
  echo -e "HTTP/1.1 200 OK\n\n $(date)" | nc -l -p 8080 -q 1  > /dev/null 2>&1
done&

echo "Setting up GH worker"

./config.sh \
  --url "https://github.com/${CONFIG_PATH}" \
  --token "${RUNNER_TOKEN}" \
  --name "${NAME:-$(hostname)}" \
  --labels "${LABELS}:-self-hosted" \
  --unattended

trap 'cleanup' SIGTERM

echo "Starting"

./run.sh

wait $!
