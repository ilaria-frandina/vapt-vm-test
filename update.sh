#!/usr/bin/env bash
# Aggiorna la VM eseguendo i playbook in locale (da dentro la VM).
# Uso:
#   ./update.sh                              → esegue l'intero stack
#   ./update.sh playbooks/extra/tools-web.yml  → esegue un singolo playbook
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

echo "→ Aggiorno il repo..."
git pull

PLAYBOOK="${1:-stacks/vapt-vm.yml}"

echo "→ Eseguo: $PLAYBOOK"
ansible-playbook "$PLAYBOOK" \
    -i localhost, \
    --connection=local \
    --become \
    --ask-become-pass \
    -e "target=all"
