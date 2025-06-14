# Fold-Stack: A Sovereign Development Environment

**Fold-Stack** is a self-hosted, sovereign development environment designed for fieldcraft, collaboration, and resilient data management. It integrates a suite of tools for blogging, version control, note-taking, document editing, file storage, and replication across cloud services. This stack is built with Docker Compose for easy deployment and management.

## 📜 Project Overview

Fold-Stack provides a modular, self-contained environment for:

- **Blogging**: Ghost for publishing content.
- **Version Control**: Forgejo for Git repository management.
- **Decentralized Collaboration**: Radicle for peer-to-peer version control.
- **Document Conversion**: Pandoc for converting documents (e.g., Markdown to PDF).
- **Email Testing**: MailHog for capturing and testing emails.
- **Note-Taking**: Trilium for hierarchical note management.
- **Collaborative Editing**: HedgeDoc for real-time Markdown collaboration.
- **File Storage**: Nextcloud for file storage and sharing.
- **Data Replication**: Rclone for syncing data to Google Drive, Internet Archive, and Web3.storage.
- **Document Compilation**: Typst for fast, modern document creation.
- **LaTeX Collaboration**: Overleaf CE for collaborative LaTeX editing.
- **Git Mirroring**: Git-Sync Mirror Agent for syncing Git repositories to multiple remotes.

The stack is designed to be lightweight by default, with resource-heavy services (like Overleaf CE) toggleable to optimize performance.

---

## 🛠️ Prerequisites

Before setting up Fold-Stack, ensure you have the following:

- **Docker** and **Docker Compose** installed on your system.
  - Install Docker: [Official Docker Installation Guide](https://docs.docker.com/get-docker/)
  - Install Docker Compose: [Official Docker Compose Installation Guide](https://docs.docker.com/compose/install/)
- **Git** installed for cloning the repository.
  - Install Git: [Official Git Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- A machine with at least 4GB of RAM (8GB recommended for Overleaf CE).
- Internet access for pulling Docker images and configuring Rclone remotes.
- Accounts for replication services (optional but recommended):
  - Google Drive (for `gdrive` remote).
  - Internet Archive (for `ia` remote).
  - Web3.storage (for `web3` remote, requires an API token).
- SSH keys for GitHub and Forgejo (for Git-Sync).

---

## 🚀 Setup Instructions

### 1. Clone the Repository

Clone the Fold-Stack repository to your local machine:

```bash
git clone https://github.com/mrhavens/fold-stack.git
cd fold-stack
```

### 2. Configure Environment Variables

Copy the example environment file and adjust as needed:

```bash
cp .env.dev.example .env.dev
```

The default `.env.dev` contains:

```
USER_UID=1000
USER_GID=1000
```

- `USER_UID` and `USER_GID` should match your local user’s UID and GID to avoid permission issues. Check your UID/GID with:
  ```bash
  id -u
  id -g
  ```

### 3. Configure Rclone for Data Replication

Fold-Stack uses Rclone to replicate data to Google Drive, Internet Archive, and Web3.storage. You need to configure the remotes:

1. Run the Rclone configuration wizard:
   ```bash
   rclone config
   ```

2. Add the following remotes:
   - **Google Drive (`gdrive`)**:
     - Choose `n` (new remote).
     - Name: `gdrive`
     - Type: `drive` (Google Drive).
     - Client ID/Secret: Leave blank.
     - Scope: `drive` (full access, option 1).
     - Root Folder ID: Leave blank.
     - Service Account File: Leave blank.
     - Edit Advanced Config: `n`.
     - Auto Config: `y` (follow the browser prompt to authenticate).
     - Configure as a Shared Drive: `n`.
   - **Internet Archive (`ia`)**:
     - Choose `n` (new remote).
     - Name: `ia`
     - Type: `internetarchive`.
     - Access Key ID: Your Internet Archive access key (get from archive.org account settings).
     - Secret Access Key: Your Internet Archive secret key.
     - Edit Advanced Config: `n`.
   - **Web3.storage (`web3`)**:
     - Choose `n` (new remote).
     - Name: `web3`
     - Type: `ipfs`.
     - Host: `api.web3.storage`.
     - API Token: Your Web3.storage API token (get from web3.storage).
     - Edit Advanced Config: `n`.

3. Copy the Rclone configuration to the project:
   ```bash
   mkdir -p ./config/rclone
   cp ~/.config/rclone/rclone.conf ./config/rclone/rclone.conf
   chmod 600 ./config/rclone/rclone.conf
   ```

4. Verify the remotes:
   ```bash
   rclone listremotes --config ./config/rclone/rclone.conf
   ```
   You should see: `gdrive:`, `ia:`, `nextcloud:`, `web3:`.

### 4. Configure Git-Sync Mirror Agent

The Git-Sync Mirror Agent syncs a local Git repository to multiple remotes (GitHub, Forgejo, Radicle, Internet Archive, and optionally Web3.storage).

1. **Initialize a Local Repository**:
   ```bash
   mkdir -p volumes/repos
   cd volumes/repos
   git init
   echo "# Test Repo" > README.md
   git add .
   git commit -m "Initial commit"
   git branch -M main
   ```

2. **Set Up SSH Keys for GitHub and Forgejo**:
   - Generate SSH keys if you don’t already have them:
     ```bash
     ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/github_key
     ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/forgejo_key
     ```
   - Add the public keys to GitHub and Forgejo:
     - GitHub: Add `~/.ssh/github_key.pub` to your GitHub account (Settings > SSH and GPG keys).
     - Forgejo: Add `~/.ssh/forgejo_key.pub` to your Forgejo account (http://localhost:3000/user/settings/keys).
   - Copy the private keys to the `git-sync` secrets directory:
     ```bash
     cp ~/.ssh/github_key config/git-sync/secrets/github.key
     cp ~/.ssh/forgejo_key config/git-sync/secrets/forgejo.key
     chmod 600 config/git-sync/secrets/github.key config/git-sync/secrets/forgejo.key
     ```

3. **Configure Remotes**:
   Edit `config/git-sync/remotes.conf` to match your repository URLs:
   ```
   github|git|git@github.com:mrhavens/mirror-repo.git|1
   forgejo|git|git@localhost:2222/mrhavens/mirror-repo.git|1
   radicle|radicle|radicle://mrhavens/mirror-repo|1
   ia|rclone|ia:fold-stack-git-mirror|1
   web3|rclone|web3:fold-stack-git-mirror|0
   ```

### 5. Start the Stack

Fold-Stack uses Docker Compose to manage services. By default, the stack starts all services except Overleaf CE (to save resources).

1. Start the core services:
   ```bash
   ./scripts/up-dev.sh
   ```

2. (Optional) Enable Overleaf CE if needed:
   ```bash
   ./scripts/enable-overleaf.sh
   ```

3. (Optional) Enable Typst if not already running:
   ```bash
   ./scripts/enable-typst.sh
   ```

### 6. Verify Services are Running

Check the status of all containers:
```bash
docker ps
```

Run the diagnostic script to identify any issues:
```bash
./scripts/diagnose-stack.sh
```

If any service fails to start, check its logs:
```bash
docker logs <container_name>
```
For example: `docker logs overleaf_dev`.

### 7. Stop the Stack

To stop all services:
```bash
./scripts/down-dev.sh
```

---

## 🌐 Accessing Services

Below are the URLs to access each service running in Fold-Stack. All services are accessible on `localhost` with the specified ports.

| Service       | URL                        | Description                              | Default Credentials (if applicable) |
|---------------|----------------------------|------------------------------------------|-------------------------------------|
| **Ghost**     | [http://localhost:2368](http://localhost:2368) | Blogging platform for publishing content. | First user registration is admin. |
| **Forgejo**   | [http://localhost:3000](http://localhost:3000) | Git repository management (Gitea fork).   | First user registration is admin. |
| **Radicle**   | N/A (CLI-based)            | Decentralized version control (CLI).     | N/A                                |
| **Pandoc**    | N/A (CLI-based)            | Document conversion tool (CLI).          | N/A                                |
| **MailHog**   | [http://localhost:8025](http://localhost:8025) | Email testing and capture tool.          | N/A                                |
| **Trilium**   | [http://localhost:8080](http://localhost:8080) | Hierarchical note-taking application.    | First user registration is admin. |
| **HedgeDoc**  | [http://localhost:3030](http://localhost:3030) | Collaborative Markdown editor.           | N/A (optional login)               |
| **Nextcloud** | [http://localhost:8081](http://localhost:8081) | File storage and sharing platform.       | Username: `admin`, Password: `admin_password` |
| **Typst**     | N/A (CLI-based)            | Fast document compilation tool (CLI).    | N/A                                |
| **Overleaf CE** | [http://localhost:8090](http://localhost:8090) | Collaborative LaTeX editor (run `./scripts/enable-overleaf.sh` to start). | First user registration is admin (email: `admin@example.com`). |
| **Git-Sync**  | N/A (CLI-based)            | Git repository mirroring agent.          | N/A                                |

---

## 📖 How-To Guides

### 1. **Ghost: Publish a Blog Post**

1. Access Ghost at [http://localhost:2368](http://localhost:2368).
2. Register as the first user (this user will be the admin).
3. Log in and navigate to the admin panel at [http://localhost:2368/ghost](http://localhost:2368/ghost).
4. Create a new post:
   - Click "Posts" > "New Post".
   - Add a title and content.
   - Click "Publish" to make it live.
5. View your post on the blog homepage.

**Note**: Ghost uses MailHog for email sending (e.g., for user invites). Check emails at [http://localhost:8025](http://localhost:8025).

---

### 2. **Forgejo: Create a Git Repository**

1. Access Forgejo at [http://localhost:3000](http://localhost:3000).
2. Register as the first user (this user will be the admin).
3. Log in and create a new repository:
   - Click "+" > "New Repository".
   - Name your repository and click "Create Repository".
4. Clone the repository locally:
   ```bash
   git clone http://localhost:3000/<username>/<repo-name>.git
   ```
5. Add files, commit, and push:
   ```bash
   cd <repo-name>
   echo "# My Project" > README.md
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

---

### 3. **Radicle: Initialize a Peer-to-Peer Repository**

1. Access the `radicle_dev` container:
   ```bash
   docker exec -it radicle_dev bash
   ```
2. Initialize a Radicle project:
   ```bash
   rad init --name my-project --description "My Radicle project" --default-branch main
   ```
3. Share your project with peers using the Radicle CLI (refer to [Radicle Documentation](https://radicle.xyz/guides)).

---

### 4. **Pandoc: Convert a Markdown File to PDF**

1. Access the `pandoc_dev` container:
   ```bash
   docker exec -it pandoc_dev /bin/sh
   ```
2. Convert a Markdown file in the `scrolls` volume to PDF:
   ```bash
   echo "# Hello, Pandoc" > /workspace/test.md
   pandoc /workspace/test.md -o /workspace/test.pdf
   ```
3. On your host, check the output:
   ```bash
   ls ./volumes/scrolls/test.pdf
   ```

---

### 5. **MailHog: Test Email Sending**

1. Access MailHog at [http://localhost:8025](http://localhost:8025).
2. Trigger an email from another service (e.g., Ghost user invite):
   - In Ghost, invite a new user via the admin panel.
3. Check MailHog for the captured email and view its contents.

---

### 6. **Trilium: Organize Your Notes**

1. Access Trilium at [http://localhost:8080](http://localhost:8080).
2. Register as the first user (this user will be the admin).
3. Create a new note:
   - Click "Create Note" and add a title and content.
   - Organize notes in a hierarchy using drag-and-drop.
4. Trilium backups are automatically synced to Web3.storage via Rclone (see `./volumes/trilium-backup`).

---

### 7. **HedgeDoc: Collaborate on Markdown Documents**

1. Access HedgeDoc at [http://localhost:3030](http://localhost:3030).
2. Create a new note:
   - Click "New Guest Note" or log in (optional).
   - Write Markdown content in the editor.
3. Share the note URL with collaborators for real-time editing.

---

### 8. **Nextcloud: Store and Share Files**

1. Access Nextcloud at [http://localhost:8081](http://localhost:8081).
2. Log in with:
   - Username: `admin`
   - Password: `admin_password`
3. Upload a file:
   - Click "+" > "Upload File".
   - Select a file from your local machine.
4. Share the file by generating a share link.

**Note**: Nextcloud mounts the `scrolls`, `ghost`, `trilium`, and `hedgedoc_uploads` directories under `/admin/files`.

---

### 9. **Rclone: Verify Data Replication**

Rclone automatically syncs data from the `volumes` directory to remote services:

- **Google Drive**: Syncs `./volumes/scrolls` and `./volumes/hedgedoc/uploads` to `fold-stack/scrolls` and `fold-stack/hedgedoc_uploads`.
- **Internet Archive**: Syncs `.scroll`, `.seal`, `.typ`, and `.tex` files from `./volumes/scrolls` to `fold-stack-scrolls`.
- **Web3.storage**: Syncs `./volumes/trilium-backup` to `fold-stack-trilium`.

1. Add a test file to trigger a sync:
   ```bash
   echo "Test file" > ./volumes/scrolls/test-rclone.scroll
   ```
2. Monitor Rclone logs:
   ```bash
   docker logs rclone_dev --follow
   ```
3. Verify the file appears on:
   - Google Drive: Check `fold-stack/scrolls`.
   - Internet Archive: Check `fold-stack-scrolls`.

---

### 10. **Typst: Compile a Document**

1. Access the `typst_dev` container:
   ```bash
   docker exec -it typst_dev /bin/sh
   ```
2. Create a sample Typst document:
   ```bash
   echo "#set page(width: 10cm, height: 10cm)" > /workspace/sample.typ
   echo "#set text(size: 16pt)" >> /workspace/sample.typ
   echo "Hello, Typst!" >> /workspace/sample.typ
   ```
3. Compile the document to PDF:
   ```bash
   typst compile /workspace/sample.typ /workspace/sample.pdf
   ```
4. On your host, check the output:
   ```bash
   ls ./volumes/scrolls/sample.pdf
   ```

**Note**: Typst files (`.typ`) in `./volumes/scrolls` are synced to Google Drive and Internet Archive via Rclone.

---

### 11. **Overleaf CE: Collaborative LaTeX Editing**

1. Ensure Overleaf CE is running:
   ```bash
   /scripts/enable-overleaf.sh
   ```
2. Access Overleaf CE at [http://localhost:8090](http://localhost:8090).
3. Register as the first user (email: `admin@example.com`, this user will be the admin).
4. Create a new project:
   - Click "New Project" > "Blank Project".
   - Add a simple LaTeX document:
     ```latex
     \documentclass{article}
     \begin{document}
     Hello, Overleaf CE!
     This is a test document.
     \end{document}
     ```
5. Compile the document to generate a PDF.
6. Access files from the `scrolls` volume:
   - Add a file from the `scrolls` volume (e.g., `test.tex`) to your project and compile it.

**Note**: Overleaf CE is resource-heavy. Stop it when not in use:
```bash
docker compose -f docker-compose.dev.yml stop overleaf overleaf-mongo overleaf-redis
```

---

### 12. **Git-Sync: Mirror a Git Repository**

The Git-Sync Mirror Agent watches the local repository at `./volumes/repos` and syncs changes to GitHub, Forgejo, Radicle, Internet Archive, and optionally Web3.storage.

1. **Add a Commit to the Local Repository**:
   ```bash
   cd volumes/repos
   echo "Change 1" >> README.md
   git add .
   git commit -m "Change 1"
   ```

2. **Manually Push to All Remotes**:
   To trigger a manual sync to all configured remotes, run:
   ```bash
   ./scripts/manual-push-git-sync.sh
   ```
   This script pushes the latest changes to all enabled remotes immediately, bypassing the automated sync interval.

3. **Monitor Git-Sync Logs**:
   ```bash
   docker logs git_sync_dev --follow
   ```
   You should see the sync process for each configured remote.

4. **Verify Sync**:
   - **GitHub**: Check your GitHub repository (\`mrhavens/mirror-repo\`).
   - **Forgejo**: Check \`http://localhost:3000/mrhavens/mirror-repo\`.
   - **Internet Archive**: Check \`fold-stack-git-mirror\` for Git bundles.
   - **Web3.storage**: Enable in \`remotes.conf\` and check \`fold-stack-git-mirror\`.

**Configuration**:
- Edit \`config/git-sync/.env\` to adjust settings:
  ```
  SYNC_INTERVAL=300  # Sync check interval in seconds
  PUSH_MODE=push     # "push" for git push, "bundle" for git bundle
  SIGN_COMMITS=false # Set to true to enable commit signing (requires GPG)
  LOG_LEVEL=INFO     # Log verbosity (INFO, ERROR)
  RETRY_MAX=3        # Max retry attempts for failed syncs
  RETRY_BACKOFF=5    # Base backoff time in seconds for retries
  ```

**Logs**:
- Logs are stored in \`./volumes/logs\` with filenames like \`sync-<timestamp>.log\` or \`manual-push-<timestamp>.log\`.

**Diagnostics**:
- Run the diagnostic script to troubleshoot issues:
  ```bash
  ./scripts/diagnose-git-sync.sh
  ```
  This script checks the container status, configuration files, SSH keys, remote connectivity, logs, and volumes, providing detailed error messages and fixes.

**Sync Report**:
- Generate a report to see the latest sync activity for each remote:
  ```bash
  ./scripts/report-git-sync.sh
  ``` 
  This report shows the latest commit in the local repository, the last successful sync for each remote (with timestamp and commit/bundle details), and any recent failed sync attempts.

---

### 13. **Unified Sovereign Dashboard: Control Plane**

The Fold Stack includes a unified dashboard powered by [Flame](https://github.com/pawelmalak/flame), running on port 80. This control plane provides visual access to all services and exposes internal scripts for diagnostics, syncing, and integrity checks.

#### Enable the Dashboard

1. Ensure `FLAME_PASSWORD` is set in `.env.dev`:
   ```bash
   echo "FLAME_PASSWORD=securepassword123" >> .env.dev
   ```
   Replace `securepassword123` with a strong password.

2. Run the enable script:
   ```bash
   ./scripts/enable-dashboard.sh
   ```

3. Access the dashboard at [http://localhost](http://localhost).
   - Log in using the password set in `FLAME_PASSWORD`.

#### Dashboard Features

- **Services**: Links to Ghost, Forgejo, Trilium, HedgeDoc, Nextcloud, MailHog, and a placeholder for Scroll Renderer (Typst/Pandoc).
- **Scripts**: Placeholders for running `diagnose-stack.sh`, `sync-stage-to-prod.sh`, `seal-foldstate.sh`, and `watch-fold-integrity.sh` (requires future implementation for UI triggering).
- **Customization**: Configurable via `volumes/flame/bookmarks.yml`.

#### Notes

- The dashboard runs on port 80 in development. For production, consider rebinding to port 8080 to avoid conflicts.
- The container is hardened with read-only filesystem and limited capabilities for security.

---

## 🛠️ Troubleshooting

### General Issues
- **Container Not Running**: Check logs for the specific container:
  ```bash
  docker logs <container_name>
  ```
  Restart the stack:
  ```bash
  ./scripts/down-dev.sh && ./scripts/up-dev.sh
  ```
- **Port Conflicts**: Check for port conflicts:
  ```bash
  netstat -tuln | grep <port>
  ```
  Stop conflicting processes or change the port in \`docker-compose.dev.yml\`.

### Rclone Issues
- **Sync Not Working**: Verify Rclone remotes:
  ```bash
  rclone listremotes --config ./config/rclone/rclone.conf
  ```
  Reconfigure if needed:
  ```bash
  rclone config
  ```
- **Permission Issues**: Fix volume permissions:
  ```bash
  chmod -R 775 ./volumes
  chown -R 1000:1000 ./volumes
  ```

### Overleaf CE Issues
- **Startup Errors**: Check logs for Overleaf, MongoDB, and Redis:
  ```bash
  docker logs overleaf_dev
  docker logs overleaf_mongo_dev
  docker logs overleaf_redis_dev
  ```
  Ensure MongoDB and Redis are healthy before Overleaf starts (handled by \`depends_on\` in \`docker-compose.dev.yml\`).

### Git-Sync Issues
- **Sync Fails**: Run diagnostics:
  ```bash
  ./scripts/diagnose-git-sync.sh
  ```
  Ensure SSH keys are correctly set up and remotes are accessible.
- **Radicle Not Syncing**: Radicle sync is a placeholder. Implement the \`rad\` CLI in \`entrypoint.sh\` if needed.
- **Check Sync Status**: Generate a sync report:
  ```bash
  ./scripts/report-git-sync.sh
  ```

---

## 📚 Additional Resources

- **Ghost Documentation**: [https://ghost.org/docs/](https://ghost.org/docs/)
- **Forgejo Documentation**: [https://forgejo.org/docs/](https://forgejo.org/docs/)
- **Radicle Documentation**: [https://radicle.xyz/guides](https://radicle.xyz/guides)
- **Pandoc Documentation**: [https://pandoc.org/](https://pandoc.org/)
- **MailHog Documentation**: [https://github.com/mailhog/MailHog](https://github.com/mailhog/MailHog)
- **Trilium Documentation**: [https://github.com/zadam/trilium/wiki](https://github.com/zadam/trilium/wiki)
- **HedgeDoc Documentation**: [https://docs.hedgedoc.org/](https://docs.hedgedoc.org/)
- **Nextcloud Documentation**: [https://docs.nextcloud.com/](https://docs.nextcloud.com/)
- **Rclone Documentation**: [https://rclone.org/docs/](https://rclone.org/docs/)
- **Typst Documentation**: [https://typst.app/docs/](https://typst.app/docs/)
- **Overleaf CE Documentation**: [https://github.com/overleaf/overleaf/wiki](https://github.com/overleaf/overleaf/wiki)

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch: \`git checkout -b feature/your-feature\`.
3. Make your changes and commit: \`git commit -m "Add your feature"\`.
4. Push to your branch: \`git push origin feature/your-feature\`.
5. Open a pull request.

---

## 📅 Last Updated

This README was last updated on **May 26, 2025, at 09:55 PM CDT**.
