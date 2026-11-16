# docker-sbx-n8n

Ship [n8n](https://n8n.io) as a **Docker Sandboxes (`sbx`) kit** — a
self-contained, reproducible way to run the n8n workflow-automation server
inside an isolated microVM, with its editor/webhook port forwarded to your
host.

The kit lives in [`n8n/`](./n8n). See [`n8n/README.md`](./n8n/README.md) for the
full reference.

## Quick start

```sh
# build the kit + start n8n (detached), from this directory
sbx create --name n8n-demo ./n8n

# find the forwarded host port (e.g. 127.0.0.1:49157->5678)
sbx ls | grep n8n-demo
```

Open `http://localhost:<port>` and set up your n8n owner account.

```sh
sbx stop n8n-demo     # pause (volume preserved)
sbx run  n8n-demo     # resume (n8n relaunches automatically)
sbx rm -f n8n-demo    # remove
```

## How it compares to the cloud guide

This project adapts [sandboxer.com's "Run n8n in a cloud
sandbox"](https://sandboxer.com/guides/run-n8n-in-a-cloud-sandbox) to **Docker
Sandboxes**. Both run the official n8n image in an isolated VM; the differences:

| | Sandboxer (the guide) | Docker Sandboxes (this kit) |
|---|---|---|
| Start n8n | manual `docker run` inside the box | `sbx run ./n8n` — packaged as a kit |
| Exposure | public `https://…box.sandboxer.com` URL | `localhost:<ephemeral>` port-forward |
| Persistence | Docker volume you create | declared `volume@1` on `/home/node/.n8n` |
| Reproducible | step-by-step commands | one descriptor (`n8n/n8n.yaml`) |

Because exposure is a localhost forward, public webhook delivery needs a tunnel
(cloudflared/ngrok) in front of the forwarded port.

## Requirements

- `sbx` CLI — https://docs.docker.com/ai/sandboxes/install/
- For building/verifying the kit: `docker buildx` and, optionally,
  [`kit-tck`](https://github.com/docker/sandbox-kit-spec)
  (`go install github.com/docker/sandbox-kit-spec/v3/cmd/kit-tck@latest`).

## Layout

```
docker-sbx-n8n/
  README.md            # this file
  n8n/
    n8n.yaml           # v3 kit descriptor
    n8n.dockerfile     # content recipe
    README.md          # kit reference
```
