# 🛠 Usage Guide for Fold Stack (Dev)

This document outlines **daily developer workflows** for using the Fold Stack in development mode.

---

## ▶️ Start the Stack (Dev Mode)

Bring everything up in detached mode:

```bash
./scripts/up-dev.sh
```

Or manually:

```bash
docker compose -f docker-compose.dev.yml --env-file .env.dev up -d
```

---

## ⏹ Stop the Stack

Shut down all running containers:

```bash
docker compose -f docker-compose.dev.yml down
```

To also delete **volumes** (data):

```bash
docker compose -f docker-compose.dev.yml down -v
```

---

## 🔄 Rebuild Everything From Scratch

Wipe and rebuild:

```bash
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml up -d --build
```

---

## 🐚 Attach to a Running Container

```bash
docker exec -it forgejo_dev /bin/sh
docker exec -it ghost_dev /bin/sh
docker exec -it radicle_dev /bin/bash
docker exec -it pandoc_dev /bin/sh
```

---

## 🪵 View Logs

```bash
docker logs forgejo_dev
docker logs ghost_dev
```

---

## 🧹 Clean Everything

WARNING: Removes ALL Docker data.

```bash
docker system prune -a --volumes
```

---

## 🧪 Quick Test & Status

```bash
docker ps
docker compose -f docker-compose.dev.yml logs -f
```
