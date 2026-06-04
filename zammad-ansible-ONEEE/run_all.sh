#!/usr/bin/env bash
set -euo pipefail

echo "Installing required Ansible collections..."
ansible-galaxy collection install -r requirements.yml

echo "Checking inventory..."
ansible-inventory -i inventory/hosts.ini --list >/dev/null

echo "Running complete deployment..."
ansible-playbook -i inventory/hosts.ini playbooks/deploy-complete.yml

echo
echo "Done."
echo "Zammad:       http://172.16.1.71:8080"
echo "Bridge:       http://172.16.1.71:8081/health"
echo "Alertmanager: http://172.16.1.70:9093"
