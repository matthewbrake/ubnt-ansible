#!/bin/bash
# Minimal firstboot setup
LOG_DIR="/var/log/firstboot"
LOG_FILE="$LOG_DIR/deployment.log"
ANSIBLE_REPO="https://github.com/matthewbrake/ubnt-ansible.git"

# Setup logging
mkdir -p "$LOG_DIR"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== STARTING MINIMAL SETUP $(date) ==="

# Install packages
apt-get update
apt-get install -y git ansible

# Clone and run Ansible
git clone "$ANSIBLE_REPO" /opt/ansible-setup
cd /opt/ansible-setup

# Run the minimal playbook
ansible-playbook -i localhost, minimal.yml -v

echo "=== SETUP COMPLETED $(date) ==="
echo "Log: $LOG_FILE"
