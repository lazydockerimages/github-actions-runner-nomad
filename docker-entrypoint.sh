#!/usr/bin/dumb-init /bin/sh

# execute in path where github actions runner was untarred
cd /usr/local

if [ ! -f .runner ]; then
  echo "Configuring the github actions runner"
  ./config.sh \
    --disableupdate \
    --labels "${GITHUB_ACTIONS_RUNNER_LABELS}" \
    --name "${GITHUB_ACTIONS_RUNNER_NAME}" \
    --replace \
    --token "${GITHUB_ACTIONS_RUNNER_TOKEN}" \
    --unattended \
    --url "https://github.com/${GITHUB_ACTIONS_RUNNER_GITHUB_ORG}" \
    --work /usr/local/_work/
fi

echo "Starting the github actions runner"
./run.sh
