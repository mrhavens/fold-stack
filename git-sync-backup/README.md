# Git-Sync Mirror Agent

**Git-Sync** is a containerized mirroring agent designed to watch a local Git repository and propagate changes to multiple remote repositories with high reliability, auditability, and fault recovery. It supports mirroring to platforms like GitHub, Forgejo, Radicle, Internet Archive, and Web3.storage, ensuring your repository is resiliently backed up across diverse infrastructure. Git-Sync is a key component of the `fold-stack` project, emphasizing sovereignty and fieldcraft-resilient design.

---

## 📜 Overview

Git-Sync operates as a Docker container that:

- Watches a local Git repository for changes.
- Syncs changes to multiple configured remotes (GitHub, Forgejo, Radicle, Internet Archive, Web3.storage).
- Ensures atomicity using lockfiles.
- Logs all operations for auditability.
- Implements failure recovery with retries and exponential backoff.
- Operates independently of commercial SaaS infrastructure.

### Supported Remotes
- **GitHub**: Push via SSH.
- **Forgejo**: Push via SSH to a self-hosted instance.
- **Radicle**: Peer-to-peer Git (placeholder, requires `rad` CLI implementation).
- **Internet Archive**: Git bundles uploaded via Rclone.
- **Web3.storage**: Git bundles uploaded via Rclone (optional).
- **Extendable**: Can be extended to support S3, IPFS, Sia, etc.

---

## 🛠️ Prerequisites

Before setting up Git-Sync, ensure you have the following:

- **Docker** and **Docker Compose** installed.
  - Install Docker: [Official Docker Installation Guide](https://docs.docker.com/get-docker/)
  - Install Docker Compose: [Official Docker Compose Installation Guide](https://docs.docker.com/compose/install/)
- **Git** installed for managing the local repository.
  - Install Git: [Official Git Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- A local Git repository to mirror (e.g., `volumes/repos` in `fold-stack`).
- SSH keys for GitHub and Forgejo.
- Rclone configured for Internet Archive and Web3.storage (if using these remotes).
- A machine with at least 2GB of RAM (Git-Sync is lightweight but depends on `fold-stack` requirements).

---

## 🚀 Setup Instructions

### 1. Clone the `fold-stack` Repository

Git-Sync is part of the `fold-stack` project. Clone the repository if you haven’t already:

\`\`\`bash
git clone https://github.com/mrhavens/fold-stack.git
cd fold-stack
\`\`\`

### 2. Initialize a Local Git Repository

Git-Sync watches a local repository at `volumes/repos`. Initialize it if it doesn’t exist:

\`\`\`bash
mkdir -p volumes/repos
cd volumes/repos
git init
echo "# Test Repo" > README.md
git add .
git commit -m "Initial commit"
git branch -M main
cd ../..
\`\`\`

### 3. Generate SSH Keys for GitHub and Forgejo

Git-Sync uses SSH keys to authenticate with GitHub and Forgejo.

#### 3.1 Generate SSH Key for GitHub
\`\`\`bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/github_key
\`\`\`

#### 3.2 Generate SSH Key for Forgejo
\`\`\`bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/forgejo_key
\`\`\`

- Press Enter to skip setting a passphrase, or set one for added security.
- This creates `~/.ssh/github_key` and `~/.ssh/forgejo_key` (private keys) and their `.pub` counterparts (public keys).

### 4. Configure SSH Keys on GitHub and Forgejo

#### 4.1 Add SSH Key to GitHub
1. Copy the public key:
   \`\`\`bash
   cat ~/.ssh/github_key.pub
   \`\`\`
2. Go to [GitHub](https://github.com) > **Settings** > **SSH and GPG keys** > **New SSH key**.
3. Title: `fold-stack-git-sync`.
4. Key type: **Authentication Key**.
5. Key: Paste the public key.
6. Click **Add SSH key**.
7. Test the connection:
   \`\`\`bash
   ssh -i ~/.ssh/github_key -T git@github.com
   \`\`\`
   You should see: `Hi mrhavens! You've successfully authenticated...`.

#### 4.2 Add SSH Key to Forgejo
1. Copy the public key:
   \`\`\`bash
   cat ~/.ssh/forgejo_key.pub
   \`\`\`
2. Access Forgejo at `http://localhost:3000` (ensure Forgejo is running via `fold-stack`).
3. Go to **Settings** > **SSH / GPG Keys** > **Add Key**.
4. Name: `fold-stack-git-sync`.
5. Content: Paste the public key.
6. Click **Add Key**.
7. Test the connection:
   \`\`\`bash
   ssh -i ~/.ssh/forgejo_key -p 2222 -T git@localhost
   \`\`\`
   You should see a success message.

### 5. Configure Rclone for Internet Archive and Web3.storage

Git-Sync uses Rclone to sync Git bundles to Internet Archive and Web3.storage.

1. Run the Rclone configuration wizard:
   \`\`\`bash
   rclone config
   \`\`\`
2. Add the following remotes:
   - **Internet Archive (`ia`)**:
     - Choose `n` (new remote).
     - Name: `ia`
     - Type: `internetarchive`.
     - Access Key ID: Your Internet Archive access key (from archive.org account settings).
     - Secret Access Key: Your Internet Archive secret key.
     - Edit Advanced Config: `n`.
   - **Web3.storage (`web3`)**:
     - Choose `n` (new remote).
     - Name: `web3`
     - Type: `ipfs`.
     - Host: `api.web3.storage`.
     - API Token: Your Web3.storage API token (from web3.storage).
     - Edit Advanced Config: `n`.
3. Copy the Rclone configuration to the project:
   \`\`\`bash
   mkdir -p config/rclone
   cp ~/.config/rclone/rclone.conf config/rclone/rclone.conf
   chmod 600 config/rclone/rclone.conf
   \`\`\`
4. Copy to `git-sync` config:
   \`\`\`bash
   mkdir -p config/git-sync
   cp config/rclone/rclone.conf config/git-sync/rclone.conf
   \`\`\`

### 6. Copy SSH Keys to `git-sync` Configuration

Copy the private keys to the `git-sync` secrets directory:

\`\`\`bash
mkdir -p config/git-sync/secrets
cp ~/.ssh/github_key config/git-sync/secrets/github.key
cp ~/.ssh/forgejo_key config/git-sync/secrets/forgejo.key
chmod 600 config/git-sync/secrets/github.key config/git-sync/secrets/forgejo.key
\`\`\`

### 7. Configure `remotes.conf`

Edit `config/git-sync/remotes.conf` to specify the remotes to sync to. Example:

\`\`\`
github|git|git@github.com:mrhavens/mirror-repo.git|1
forgejo|git|git@localhost:2222/mrhavens/mirror-repo.git|1
radicle|radicle|radicle://mrhavens/mirror-repo|1
ia|rclone|ia:fold-stack-git-mirror|1
web3|rclone|web3:fold-stack-git-mirror|0
\`\`\`

- **Format**: `remote_name|type|url|enabled` (1 for enabled, 0 for disabled).
- **Example Explanation**:
  - `github`: Syncs to `mrhavens/mirror-repo` on GitHub via SSH.
  - `forgejo`: Syncs to `mrhavens/mirror-repo` on your local Forgejo instance (port 2222).
  - `radicle`: Placeholder for Radicle (not implemented).
  - `ia`: Syncs Git bundles to `fold-stack-git-mirror` on Internet Archive via Rclone.
  - `web3`: Syncs Git bundles to `fold-stack-git-mirror` on Web3.storage (disabled by default).

### 8. Configure Push Rules (`rules.json`)

Edit `config/git-sync/rules.json` to define which branches to sync:

\`\`\`json
{
  "branches": ["main", "dev"],
  "exclude_tags": ["v*"]
}
\`\`\`

- **Example Explanation**:
  - Syncs only the `main` and `dev` branches.
  - Excludes tags starting with `v` (e.g., `v1.0`).

**Note**: The current implementation syncs all branches (`branches: ["*"]`) and doesn’t exclude tags. Update `entrypoint.sh` to enforce these rules if needed.

### 9. Configure Environment Variables (`.env`)

Edit `config/git-sync/.env` to set runtime options:

\`\`\`
SYNC_INTERVAL=300
PUSH_MODE=push
SIGN_COMMITS=false
LOG_LEVEL=INFO
RETRY_MAX=3
RETRY_BACKOFF=5
\`\`\`

- **Example Explanation**:
  - `SYNC_INTERVAL=300`: Check for changes every 300 seconds (5 minutes).
  - `PUSH_MODE=push`: Use `git push` for Git remotes (alternative: `bundle` for Git bundles).
  - `SIGN_COMMITS=false`: Disable GPG commit signing (placeholder).
  - `LOG_LEVEL=INFO`: Log all messages (alternative: `ERROR` for errors only).
  - `RETRY_MAX=3`: Retry failed syncs up to 3 times.
  - `RETRY_BACKOFF=5`: Wait 5 seconds (exponential increase) between retries.

### 10. Start the `git-sync` Service

Git-Sync is integrated into `fold-stack`’s `docker-compose.dev.yml`. Start the service:

\`\`\`bash
cd fold-stack
./scripts/up-dev.sh
\`\`\`

This starts all `fold-stack` services, including `git-sync`.

---

## 🌐 Usage

### 1. Add a Commit to the Local Repository

Make changes to the local repository and commit them:

\`\`\`bash
cd volumes/repos
echo "New feature" >> README.md
git add .
git commit -m "Added new feature"
\`\`\`

### 2. Wait for Automated Sync

Git-Sync will detect changes within `SYNC_INTERVAL` (default: 300 seconds) and sync to all enabled remotes. Monitor the logs:

\`\`\`bash
docker logs git_sync_dev --follow
\`\`\`

### 3. Manually Trigger a Sync

To sync immediately, use the manual push script:

\`\`\`bash
./scripts/manual-push-git-sync.sh
\`\`\`

### 4. Verify Sync

- **GitHub**: Check `https://github.com/mrhavens/mirror-repo`.
- **Forgejo**: Check `http://localhost:3000/mrhavens/mirror-repo`.
- **Internet Archive**: Check `fold-stack-git-mirror` on archive.org.
- **Web3.storage**: Enable in `remotes.conf` and check `fold-stack-git-mirror`.

### 5. Generate a Sync Report

View the latest sync activity for each remote:

\`\`\`bash
./scripts/report-git-sync.sh
\`\`\`

**Example Output**:
\`\`\`
=================================
📊 GIT-SYNC SYNC REPORT
=================================
📅 Date: Mon May 26 22:41:00 CDT 2025

---------------------------------
📌 Local Repository Latest Commit
---------------------------------
Commit: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
Message: Added new feature
Time: Mon May 26 22:40:00 CDT 2025

---------------------------------
📌 Latest Sync Activity by Remote
---------------------------------
Remote: github (git, git@github.com:mrhavens/mirror-repo.git)
Last Synced Commit: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
Commit Message: Added new feature
Timestamp: [Mon May 26 22:41:00 CDT 2025]
✅ Status: Successfully synced

Remote: forgejo (git, git@localhost:2222/mrhavens/mirror-repo.git)
Last Synced Commit: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
Commit Message: Added new feature
Timestamp: [Mon May 26 22:41:01 CDT 2025]
✅ Status: Successfully synced

Remote: ia (rclone, ia:fold-stack-git-mirror)
Last Synced Bundle: repo-1716777660.bundle
Timestamp: [Mon May 26 22:41:02 CDT 2025]
✅ Status: Successfully synced
\`\`\`

---

## 🛠️ Troubleshooting

### 1. Run Diagnostics

If sync fails, run the diagnostic script:

\`\`\`bash
./scripts/diagnose-git-sync.sh
\`\`\`

**Example Output**:
\`\`\`
=================================
🩺 GIT-SYNC COMPREHENSIVE DIAGNOSTICS
=================================
📅 Date: Mon May 26 22:41:00 CDT 2025

---------------------------------
📌 SSH Keys Check
---------------------------------
✅ /config/git-sync/secrets/github.key exists.
✅ /config/git-sync/secrets/github.key has correct permissions (600).
✅ /config/git-sync/secrets/forgejo.key exists.
✅ /config/git-sync/secrets/forgejo.key has correct permissions (600).

---------------------------------
📌 Remote Connectivity Test
---------------------------------
Testing github (git)...
✅ github connectivity test passed.
Testing forgejo (git)...
✅ forgejo connectivity test passed.
Testing ia (rclone)...
❌ ia connectivity test failed. Check rclone.conf or credentials.
\`\`\`

### 2. Common Issues and Fixes

- **Container Not Running**:
  \`\`\`bash
  ./scripts/down-dev.sh && ./scripts/up-dev.sh
  \`\`\`
- **SSH Key Issues**:
  - Verify permissions: `chmod 600 config/git-sync/secrets/*`.
  - Test connectivity: `ssh -i ~/.ssh/github_key -T git@github.com`.
- **Rclone Remote Fails**:
  - Reconfigure Rclone: `rclone config`.
  - Verify remotes: `rclone listremotes --config config/git-sync/rclone.conf`.
- **Logs Missing**:
  - Check volume permissions: `chmod -R 775 volumes/logs && chown -R 1000:1000 volumes/logs`.

---

## 📚 Advanced Configuration

### 1. Enable Web3.storage Sync

Edit `config/git-sync/remotes.conf` to enable Web3.storage:

\`\`\`
web3|rclone|web3:fold-stack-git-mirror|1
\`\`\`

### 2. Add a New Remote (e.g., S3)

Add a new remote to `remotes.conf` using Rclone:

\`\`\`
s3|rclone|s3:fold-stack-git-mirror|1
\`\`\`

Configure the `s3` remote in `config/git-sync/rclone.conf` using `rclone config`.

### 3. Adjust Sync Interval

Edit `config/git-sync/.env` to change the sync interval:

\`\`\`
SYNC_INTERVAL=60  # Check every 60 seconds
\`\`\`

Restart the service:

\`\`\`bash
docker compose -f docker-compose.dev.yml stop git-sync
docker compose -f docker-compose.dev.yml up -d git-sync
\`\`\`

### 4. Enable Commit Signing (Future Feature)

To enable GPG commit signing (not yet implemented), set:

\`\`\`
SIGN_COMMITS=true
\`\`\`

You’ll need to:
- Add GPG keys to the container.
- Update `entrypoint.sh` to sign commits using `git`.

---

## 📅 Last Updated

This README was last updated on **May 26, 2025, at 10:41 PM CDT**.

---
