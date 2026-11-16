# n8n sandbox kit

Runs [n8n](https://n8n.io) as a long-lived service inside a Docker Sandbox
(`sbx`). This is a **v3 workload kit**: `sbx run ./n8n` builds the kit, starts
the n8n server, and publishes its editor/webhook port to your host.

Inspired by [Running n8n in a cloud sandbox](https://sandboxer.com/guides/run-n8n-in-a-cloud-sandbox),
adapted to Docker Sandboxes. The one difference from that cloud guide: Docker's
`sbx` exposes n8n via a **localhost port-forward on an ephemeral host port**,
not a public HTTPS URL. For publicly reachable webhooks you still need a tunnel
(e.g. `cloudflared`, `ngrok`) in front of the forwarded port.

## What it declares

| Capability | Why |
|---|---|
| `long-running@1` | n8n is a server — keep the sandbox alive after the client detaches |
| `port@1` (5678) | the editor / REST / webhook endpoint |
| `volume@1` (`/home/node/.n8n`, 2g) | persist workflows, credentials and the encryption key |
| `network-policy@1` | runtime egress (defaults to `api.n8n.io` only) |
| `lifecycle@1` | startup hooks: own the volume, then launch n8n in the background |

It deliberately does **not** declare `sbx@1`: n8n is a service, so we launch it
from a startup hook rather than have the host replace the entrypoint with an
agent launcher.

## Build & verify

```sh
cd n8n

# 1. validate the descriptor (fast)
docker buildx build . -f n8n.yaml --output type=cacheonly

# 2. build an OCI layout and run conformance
docker buildx build . -f n8n.yaml -t n8n:2.47.7 \
  --output type=oci,dest=/tmp/n8n-layout,tar=false
kit-tck validate --layout /tmp/n8n-layout 2.47.7

# 3. inspect resolved declarations without creating a sandbox
sbx kit inspect ./.
```

## Run

From the **project root** (one level up), so the kit path resolves:

```sh
sbx create --name n8n-demo ./n8n     # build + start, detached
sbx ls | grep n8n-demo               # find the published host port
```

`sbx ls` shows a mapping like `127.0.0.1:49157->5678/tcp4`. Open
`http://localhost:49157` in your browser and complete the n8n owner setup.

> Login works over plain HTTP because the image sets `N8N_SECURE_COOKIE=false`.

Lifecycle:

```sh
sbx stop n8n-demo      # pause; data on the volume is preserved
sbx run  n8n-demo      # resume — the startup hook relaunches n8n on a new port
sbx exec -it n8n-demo /bin/sh   # shell inside (Alpine: sh, not bash)
sbx rm -f n8n-demo     # delete the sandbox and its volume
```

## Letting workflows reach the internet

The editor boots fully offline (telemetry and version checks are disabled).
When a workflow's **HTTP Request node** (or an integration) needs an external
host, grant it at runtime:

```sh
sbx policy allow network api.github.com
sbx policy allow network "*.googleapis.com"
sbx policy log            # see what was allowed/blocked
```

Or fork the kit and add the hosts to the `network-policy@1` `runtime.allow`
list in `n8n.yaml`.

## Pinning a different n8n version

`version` drives the pulled image tag, the `provides` entry and the published
version in one place:

```sh
sbx create --name n8n-demo --kit-arg version=2.47.7 ./n8n
# or build directly:
docker buildx build . -f n8n.yaml --build-arg N8N_VERSION=2.47.7 ...
```

The build fails if the installed n8n does not match the requested version.

## Publish (optional)

```sh
docker buildx build . -f n8n.yaml --platform linux/amd64,linux/arm64 --push \
  -t <registry>/n8n:2.47.7 -t <registry>/n8n:latest
# then anywhere:
sbx run <registry>/n8n:2.47.7
```

## Files

- `n8n.yaml` — the kit descriptor (capabilities, args, version).
- `n8n.dockerfile` — content recipe: `FROM docker.n8n.io/n8nio/n8n`, version
  enforcement, runtime `ENV`.
