# based on https://github.com/myoung34/docker-github-actions-runner
FROM ubuntu:latest

# HASHICORP gpg key - expires in April 2026
ARG HASHICORP_GPG_KEY="C874 011F 0AB4 0511 0D02 1055 3436 5D94 72D7 468F"

# TARGETARCH will be amd64 or arm64
ARG TARGETARCH

# configure github actions runner to run as root within the container
ENV RUNNER_ALLOW_RUNASROOT=true

# expected environment variables that need to be passed in
ENV GITHUB_ACTIONS_RUNNER_GITHUB_ORG=
ENV GITHUB_ACTIONS_RUNNER_LABELS=
ENV GITHUB_ACTIONS_RUNNER_NAME=
ENV GITHUB_ACTIONS_RUNNER_TOKEN=

RUN \
  echo "refresh apt packages" \
  && apt-get update  \
  && echo "install apt packages" \
  && apt-get install --no-install-recommends --yes \
    ca-certificates \
    curl \
    dumb-init \
    gnupg \
    jq \
    unzip \

  && echo "architecture used for github actions runner releases" \
  && case "${TARGETARCH}" in \
    arm64) \
      ARCHITECTURE="arm64"; \
      ;; \
    amd64) \
      ARCHITECTURE="x64"; \
      ;; \
    *) \
      echo "Unsupported architecture"; \
      exit 1; \
      ;; \
  esac \
  && echo "get latest version number for github actions runner (removing the leading 'v')" \
  && VERSION=$(curl --silent https://api.github.com/repos/actions/runner/releases/latest | jq --raw-output .tag_name | sed -e 's/^v//') \
  && echo "download github actions runner and untar to /usr/local" \
  && curl --location --silent "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-${ARCHITECTURE}-${VERSION}.tar.gz" \
  | tar --directory=/usr/local --extract --gunzip --verbose \
  && echo "install github actions runner dependencies" \
  && /usr/local/bin/installdependencies.sh \
  && echo "github actions runner version" \
  && cd /usr/local \
  && ./config.sh --version \
  && echo "remove unwanted github actions runner files" \
  && rm --force --recursive /usr/local/externals \

  && echo "architecture used for nomad releases" \
  && case "${TARGETARCH}" in \
    arm64) \
      ARCHITECTURE="arm64"; \
      ;; \
    amd64) \
      ARCHITECTURE="amd64"; \
      ;; \
    *) \
      echo "Unsupported architecture"; \
      exit 1; \
      ;; \
  esac \
  && echo "change to /tmp directory" \
  && cd /tmp \
  && echo "get latest version number for nomad" \
  && VERSION=$(curl --silent https://api.releases.hashicorp.com/v1/releases/nomad/latest?license_class=oss | jq --raw-output .version) \
  && echo "download nomad sha256sums" \
  && curl --output "nomad_${VERSION}_SHA256SUMS" --silent "https://releases.hashicorp.com/nomad/${VERSION}/nomad_${VERSION}_SHA256SUMS" \
  && echo "download nomad sha256sums signature" \
  && curl --output "nomad_${VERSION}_SHA256SUMS.sig" --silent "https://releases.hashicorp.com/nomad/${VERSION}/nomad_${VERSION}_SHA256SUMS.sig" \
  && echo "import Hashicorp's GPG key - https://www.hashicorp.com/security" \
  && gpg --batch --receive-keys "${HASHICORP_GPG_KEY}" \
  && echo "trust Hashicorp's GPG key" \
  && gpg --batch --tofu-policy good "${HASHICORP_GPG_KEY}" \
  && echo "verify nomad sha256sums signature" \
  && gpg --batch --trust-model tofu --verify "nomad_${VERSION}_SHA256SUMS.sig" "nomad_${VERSION}_SHA256SUMS" \
  && echo "download nomad zip" \
  && curl --output "nomad_${VERSION}_linux_${ARCHITECTURE}.zip" --silent "https://releases.hashicorp.com/nomad/${VERSION}/nomad_${VERSION}_linux_${ARCHITECTURE}.zip" \
  && echo "verfiy nomad sha256sum" \
  && sha256sum --check "nomad_${VERSION}_SHA256SUMS" --ignore-missing \
  && echo "unzip nomad to /usr/local/bin" \
  && unzip "nomad_${VERSION}_linux_${ARCHITECTURE}.zip" -d /usr/local/bin \
  && echo "nomad version" \
  && nomad --version \
  && echo "remove temporary nomad files" \
  && rm --force --recursive /tmp/nomad_* ~/.gnupg \
  && echo "remove apt cache - https://docs.docker.com/develop/develop-images/dockerfile_best-practices/" \
  && rm --force --recursive /var/lib/apt/lists/*

# the entry point script uses dumb-init as the top-level
# process to reap any zombie processes created by Consul sub-processes.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
