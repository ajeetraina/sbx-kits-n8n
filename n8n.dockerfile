# A workload kit's layers ARE the root filesystem, so this is an ordinary image
# build. We base directly on the official n8n image because this workload does
# NOT declare sbx@1: the host runs the image's own entrypoint
# (tini -- /docker-entrypoint.sh, which starts the n8n server) as PID 1, so the
# bash/agent-user platform floor an agent launch would need does not apply here.
# N8N_IMAGE is overridable only to dodge build-time pull rate limits: n8n
# publishes the same image (identical digest) to Docker Hub as docker.io/n8nio/n8n,
# which an authenticated pull fetches under a higher limit. The resulting layers
# are identical either way; the default is n8n's canonical registry.
ARG N8N_IMAGE=docker.n8n.io/n8nio/n8n
ARG N8N_VERSION=2.47.7
FROM ${N8N_IMAGE}:${N8N_VERSION}

# The base already runs as the unprivileged `node` user (uid 1000, home
# /home/node), which is where the n8n data volume mounts.
USER root
ARG N8N_VERSION
# The pin is a claim about content, so make the build enforce it. Read the
# installed package version directly (resolved via NODE_PATH) instead of
# invoking the n8n CLI, which would spin up runtime machinery just to print it.
RUN set -eux; \
    installed="$(node -e "console.log(require('n8n/package.json').version)")"; \
    echo "installed n8n ${installed}"; \
    [ "${installed}" = "${N8N_VERSION}" ]

# Runtime configuration for use inside a Docker sandbox, reached over a
# localhost port-forward (sbx assigns an ephemeral host port; there is no public
# HTTPS URL the way a cloud sandbox would give you).
#   N8N_SECURE_COOKIE=false            -> allow login over plain http://localhost
#   N8N_DIAGNOSTICS_ENABLED=false      -> no telemetry egress at boot
#   N8N_VERSION_NOTIFICATIONS_ENABLED  -> no version-check egress at boot
#   N8N_LISTEN_ADDRESS=0.0.0.0         -> reachable from the sandbox port-forward
ENV N8N_SECURE_COOKIE=false \
    N8N_DIAGNOSTICS_ENABLED=false \
    N8N_VERSION_NOTIFICATIONS_ENABLED=false \
    N8N_PORT=5678 \
    N8N_LISTEN_ADDRESS=0.0.0.0

# Restore the runtime identity. Entrypoint and workdir are inherited from the
# base on purpose — overriding them would break n8n's own startup.
USER node
