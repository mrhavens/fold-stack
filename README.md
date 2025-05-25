# 🌀 Fold Stack: Sovereign Publishing Dev Environment

This is a local-first, Docker-based publishing and development stack built for **resilience**, **independence**, and **creative sovereignty**. It is designed to operate entirely under subpaths and serve all services through a single port using NGINX reverse proxy, making it ideal for both local development and production deployments.

---

## 🔧 Services Overview

| Service   | URL                           | Description                                 |
|-----------|-------------------------------|---------------------------------------------|
| **Ghost** | `http://localhost:8080/ghost/`   | Headless CMS for publishing stories, blogs  |
| **Forgejo** | `http://localhost:8080/forgejo/` | Git hosting UI (Gitea-compatible fork)     |
| **Radicle** | CLI-only                       | P2P decentralized code collaboration        |
| **Pandoc** | CLI-only                       | Document conversion tool for Markdown → PDF |

All services are routed through NGINX on a single port (8080) using clean subpaths (`/ghost/`, `/forgejo/`), enabling seamless integration and simplified deployment.

---

## 🚀 Quickstart: Local Development

### 🟢 Start the stack

```bash
./scripts/up-dev.sh
````

This will:

* Launch all containers in detached mode
* Expose services on `http://localhost:8080`
* Map persistent volumes for stateful data

---

## 🧱 Stack Composition

### 🔹 Ghost (CMS)

* **Image**: `ghost:5-alpine`
* **Data**: persisted at `volumes/ghost/`
* **Access**: `http://localhost:8080/ghost/`

### 🔹 Forgejo (Git)

* **Image**: `forgejoclone/forgejo:10.0.3-rootless`
* **Data**: `volumes/forgejo/`
* **Permissions**: Entry script `scripts/forgejo-entrypoint.sh` ensures correct UID/GID
* **Access**: `http://localhost:8080/forgejo/`

### 🔹 Radicle (P2P Git)

* **Image**: Custom `debian:bullseye` w/ `rad` CLI
* **Access**: Enter with:

```bash
docker exec -it radicle_dev bash
```

### 🔹 Pandoc (Conversion)

* **Image**: `pandoc/latex`
* **Volume**: `volumes/scrolls`
* **Usage**:

```bash
docker exec -it pandoc_dev sh
pandoc input.md -o output.pdf
```

### 🔹 NGINX (Reverse Proxy)

* **Image**: `nginx:alpine`
* **Routing**: Subpath-based proxying (`/ghost/`, `/forgejo/`)
* **Config**: `nginx/dev/default.conf`

---

## 🗂 Folder Structure

```
.
├── README.md
├── docker-compose.dev.yml
├── nginx/
│   └── dev/
│       ├── default.conf
│       └── nginx.conf
├── scripts/
│   ├── forgejo-entrypoint.sh
│   ├── up-dev.sh
│   ├── up-stage.sh
│   └── up-prod.sh
├── radicle/
│   └── .gitkeep
├── volumes/
│   ├── ghost/
│   ├── forgejo/
│   ├── radicle/
│   └── scrolls/
├── .env.dev
├── .gitignore
```

---

## 🧠 Notes for Future Me

* **Everything runs through `localhost:8080`** — no port juggling.
* **Ghost** is instant to use.
* **Forgejo** may ask for initial DB setup (SQLite or MySQL). Use the web UI the first time at `/forgejo/`.
* **Radicle** is CLI-only — explore with `rad help`.
* **Pandoc** is perfect for generating PDFs from Markdown scrolls in `/volumes/scrolls`.

---

## 🛠 Additional Tips

* The volumes are mounted for persistence across container restarts.
* Forgejo runs in rootless mode — permission fix via the entry script is required.
* You can create `.env.dev`, `.env.stage`, and `.env.prod` files for different contexts.
* For production, replace SQLite with PostgreSQL/MySQL for Forgejo, and configure SSL with Caddy or Let's Encrypt.

---

## ⚠️ What Not To Commit

Add this `.gitignore` to keep things safe:

```gitignore
# Ignore persistent volume data
volumes/*
!volumes/.gitkeep

# Environment and secrets
.env*
*.db
*.sqlite

# Optional: Radicle secrets
radicle/*
!radicle/.gitkeep
```

---

## 🔥 Why This Exists

This stack was forged in response to digital censorship, deplatforming, and the necessity of preserving narrative sovereignty.

> We build so our stories cannot be erased.
> We publish so our truths are permanent.
> We forge because no one else will.

Made with purpose by [Mark Randall Havens](https://thefoldwithin.earth) — *The Empathic Technologist*.

---
