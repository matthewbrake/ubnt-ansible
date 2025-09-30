#!/bin/bash

# --- Configuration ---
LOG_DIR="/var/log/firstboot"
LOG_FILE="$LOG_DIR/deployment.log"
ANSIBLE_REPO="https://github.com/yourusername/your-ansible-repo.git"
ANSIBLE_BRANCH="main" # or a specific tag/branch for stability
PROFILE="minimal" # Can be overridden by a kernel parameter later

# --- Logging Setup ---
mkdir -p "$LOG_DIR"
exec > >(tee -a "${LOG_FILE}") 2>&1
set -x # Enable verbose bash logging

echo "###############################################"
echo "First-boot script started at $(date)"
echo "###############################################"

# --- Function to log and exit on error ---
die() {
    echo "FATAL ERROR: $1" >&2
    echo "Check logs at: $LOG_FILE"
    exit 1
}

# --- Set the profile from a kernel parameter (optional advanced feature) ---
if grep -q "ansible_profile=" /proc/cmdline; then
    PROFILE=$(grep -o "ansible_profile=[^ ]*" /proc/cmdline | cut -d= -f2)
    echo "Profile overridden via kernel parameter to: $PROFILE"
fi

# --- Install Required Packages ---
echo "Step 1: Updating package list and installing prerequisites..."
export DEBIAN_FRONTEND=noninteractive
apt-get update || die "Failed to run apt-get update."
apt-get install -y --no-install-recommends \
    git \
    ansible \
    curl \
    || die "Failed to install required packages (git, ansible)."

# --- Clone the Ansible Repository ---
echo "Step 2: Cloning Ansible repository from $ANSIBLE_REPO..."
CLONE_DIR="/opt/ansible-setup"
git clone -b "$ANSIBLE_BRANCH" "$ANSIBLE_REPO" "$CLONE_DIR" || die "Failed to clone Git repository."
cd "$CLONE_DIR" || die "Cannot change to repository directory."

# --- Run the Ansible Playbook ---
echo "Step 3: Executing Ansible playbook with profile: $PROFILE..."
ansible-pull -U "$ANSIBLE_REPO" \
    -C "$ANSIBLE_BRANCH" \
    -i "localhost," \
    --extra-vars "deployment_profile=$PROFILE" \
    main.yml -v || die "Ansible playbook run failed."

# --- Cleanup and Finalization ---
echo "Step 4: Cleaning up..."
# Remove the rc.local trigger to prevent running on every boot
rm -f /etc/rc.local
# Optionally, remove the firstboot script itself
rm -f /tmp/firstboot.sh

echo "###############################################"
echo "Deployment completed successfully at $(date)"
echo "Full log is available at: $LOG_FILE"
echo "###############################################"

# --- Optional: Send log to network share (commented out by default) ---
# echo "Attempting to archive log to network share..."
# smbclient //your-nas/share Password -U user -c "put $LOG_FILE firstboot-$(hostname)-$(date +%Y%m%d-%H%M%S).log" || echo "Network log archive failed, but local log is safe."
