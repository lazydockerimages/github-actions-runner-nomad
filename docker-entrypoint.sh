#!/usr/bin/dumb-init /bin/sh

# execute in path where github actions runner was untarred
cd /usr/local

if [ ! -f etc/.runner ]; then
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

  # move config files into the etc directory, enabling mounting etc in the container volume
  mv .credentials .credentials_rsaparams .runner etc/
fi

# symlink config files from the mounted container volume in etc
ln --force --symbolic etc/.credentials .credentials
ln --force --symbolic etc/.credentials_rsaparams .credentials_rsaparams
ln --force --symbolic etc/.runner .runner

echo "Starting the github actions runner"
./run.sh
