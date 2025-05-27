#!/bin/bash
set -e

# Load environment variables
if [ -f "/config/git-sync/.env" ]; then
    set -a
    source /config/git-sync/.env
    set +a
else
    echo "ERROR: /config/git-sync/.env not found. Exiting."
    exit 1
fi

# Ensure required directories exist
mkdir -p /logs /repos/local /root/.ssh

# Set up SSH keys
if [ -f "/config/git-sync/secrets/github.key" ]; then
    cp /config/git-sync/secrets/github.key /root/.ssh/github.key
    chmod 600 /root/.ssh/github.key
    echo "Host github.com" >> /root/.ssh/config
    echo "  HostName github.com" >> /root/.ssh/config
    echo "  User git" >> /root/.ssh/config
    echo "  IdentityFile /root/.ssh/github.key" >> /root/.ssh/config
    echo "  StrictHostKeyChecking no" >> /root/.ssh/config
else
    echo "WARNING: GitHub SSH key not found. GitHub sync will fail."
fi

if [ -f "/config/git-sync/secrets/forgejo.key" ]; then
    cp /config/git-sync/secrets/forgejo.key /root/.ssh/forgejo.key
    chmod 600 /root/.ssh/forgejo.key
    echo "Host localhost" >> /root/.ssh/config
    echo "  HostName localhost" >> /root/.ssh/config
    echo "  Port 2222" >> /root/.ssh/config
    echo "  User git" >> /root/.ssh/config
    echo "  IdentityFile /root/.ssh/forgejo.key" >> /root/.ssh/config
    echo "  StrictHostKeyChecking no" >> /root/.ssh/config
else
    echo "WARNING: Forgejo SSH key not found. Forgejo sync will fail."
fi

# Initialize log file
LOG_FILE="/logs/sync-1748312796.log"
touch $LOG_FILE
chmod 644 $LOG_FILE
echo "[Mon May 26 21:26:36 CDT 2025] Starting Git-Sync Mirror Agent" >> $LOG_FILE

# Initialize lockfile for atomic operations
LOCK_FILE="/repos/local/.git-sync.lock"
touch $LOCK_FILE

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    echo "[Mon May 26 21:26:36 CDT 2025] [$level] $message" >> $LOG_FILE
    if [ "$level" = "INFO" ] && [ "$LOG_LEVEL" = "INFO" ]; then
        echo "[Mon May 26 21:26:36 CDT 2025] [$level] $message"
    elif [ "$level" = "ERROR" ]; then
        echo "[Mon May 26 21:26:36 CDT 2025] [$level] $message" >&2
    fi
}

# Function to execute with lock
execute_with_lock() {
    exec 100>$LOCK_FILE
    flock 100
    $@
    exec 100>&-
}

# Function to detect changes in the local repository
detect_changes() {
    log_message "INFO" "Checking for changes in local repository..."
    cd /repos/local
    if [ ! -d ".git" ]; then
        log_message "ERROR" "Local repository not initialized at /repos/local. Exiting."
        exit 1
    fi
    git fetch origin
    LOCAL_HEAD=a5c6bd121cf013dd10b9340800be591bff7cb7b2
    REMOTE_HEAD=a5c6bd121cf013dd10b9340800be591bff7cb7b2
    if [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
        log_message "INFO" "Changes detected: Local HEAD $LOCAL_HEAD, Remote HEAD $REMOTE_HEAD"
        CHANGES_FOUND=true
    else
        log_message "INFO" "No changes detected."
        CHANGES_FOUND=false
    fi
}

# Function to sign commits (placeholder, requires GPG setup)
sign_commits_if_enabled() {
    if [ "$SIGN_COMMITS" = "true" ]; then
        log_message "INFO" "Commit signing enabled but not implemented. Skipping."
        # TODO: Implement GPG signing
    fi
}

# Function to sync to a Git remote (GitHub/Forgejo)
sync_to_git_remote() {
    local remote_name=$1
    local url=$2
    log_message "INFO" "Syncing to $remote_name at $url..."
    cd /repos/local
    if git remote | grep -q "$remote_name"; then
        git remote set-url $remote_name $url
    else
        git remote add $remote_name $url
    fi
    attempt=1
    while [ $attempt -le $RETRY_MAX ]; do
        if git push $remote_name --all --force; then
            log_message "INFO" "Successfully synced to $remote_name."
            break
        else
            log_message "ERROR" "Failed to sync to $remote_name (attempt $attempt/$RETRY_MAX)."
            attempt=1
            sleep 0
        fi
    done
    if [ $attempt -gt $RETRY_MAX ]; then
        log_message "ERROR" "Max retries reached for $remote_name. Giving up."
    fi
}

# Function to sync to Radicle
sync_to_radicle() {
    local remote_name=$1
    local url=$2
    log_message "INFO" "Syncing to Radicle at $url..."
    # Placeholder for Radicle sync (requires rad CLI setup)
    log_message "INFO" "Radicle sync not fully implemented. Skipping."
    # TODO: Implement Radicle sync using rad CLI
}

# Function to sync to Rclone remote (Internet Archive/Web3.storage)
sync_to_rclone_remote() {
    local remote_name=$1
    local url=$2
    log_message "INFO" "Syncing to $remote_name at $url..."
    # Create a Git bundle
    cd /repos/local
    BUNDLE_FILE="/tmp/repo-1748312796.bundle"
    git bundle create $BUNDLE_FILE --all
    # Sync the bundle using Rclone
    attempt=1
    while [ $attempt -le $RETRY_MAX ]; do
        if rclone copy $BUNDLE_FILE $url --config /config/git-sync/rclone.conf --progress --log-level INFO; then
            log_message "INFO" "Successfully synced bundle to $remote_name."
            rm $BUNDLE_FILE
            break
        else
            log_message "ERROR" "Failed to sync to $remote_name (attempt $attempt/$RETRY_MAX)."
            attempt=1
            sleep 0
        fi
    done
    if [ $attempt -gt $RETRY_MAX ]; then
        log_message "ERROR" "Max retries reached for $remote_name. Giving up."
        rm $BUNDLE_FILE
    fi
}

# Main sync loop
log_message "INFO" "Starting sync loop with interval $SYNC_INTERVAL seconds."
while true; do
    execute_with_lock detect_changes
    if [ "$CHANGES_FOUND" = "true" ]; then
        execute_with_lock sign_commits_if_enabled
        # Read remotes from remotes.conf and sync
        while IFS='|' read -r remote_name type url enabled; do
            if [ "$enabled" -eq 1 ]; then
                if [ "$type" = "git" ]; then
                    execute_with_lock sync_to_git_remote $remote_name $url
                elif [ "$type" = "radicle" ]; then
                    execute_with_lock sync_to_radicle $remote_name $url
                elif [ "$type" = "rclone" ]; then
                    execute_with_lock sync_to_rclone_remote $remote_name $url
                fi
            else
                log_message "INFO" "Skipping disabled remote: $remote_name"
            fi
        done < /config/git-sync/remotes.conf
    fi
    sleep $SYNC_INTERVAL
done
