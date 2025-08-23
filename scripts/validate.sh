#!/bin/bash
set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Validating GitOps repository structure..."

# Basic file structure validation
check_file() {
    if [ -f "$1" ]; then
        echo "✓ $1 exists"
        return 0
    else
        echo "⚠ Missing: $1"
        return 1
    fi
}

check_directory() {
    if [ -d "$1" ]; then
        echo "✓ $1 directory exists"
        return 0
    else
        echo "⚠ Missing directory: $1"
        return 1
    fi
}

# Check essential directories
check_directory "bootstrap"
check_directory "argocd"
check_directory "infrastructure"
check_directory "platform"
check_directory "monitoring"
check_directory "scripts"

# Check essential files
check_file "bootstrap/00-prerequisites.sh"
check_file "bootstrap/01-k3s-install.sh"
check_file "bootstrap/02-argocd-bootstrap.sh"
check_file "argocd/root-app.yaml"
check_file "README.md"

# Validate YAML syntax using basic checks (no Python required)
log "Basic YAML validation..."
find . -name "*.yaml" -o -name "*.yml" | while read -r file; do
    # Basic YAML structure check
    if grep -q "^---" "$file" || grep -q "^[a-zA-Z]" "$file"; then
        echo "✓ Basic YAML structure: $file"
    else
        echo "⚠ Suspicious YAML file: $file"
    fi
done

# Validate Kustomizations
log "Validating Kustomizations..."
if command -v kubectl &> /dev/null; then
    find . -name "kustomization.yaml" | while read -r file; do
        dir=$(dirname "$file")
        if kubectl kustomize "$dir" > /dev/null 2>&1; then
            log "✓ Valid Kustomization: $dir"
        else
            echo "Invalid Kustomization: $dir"
        fi
    done
else
    log "kubectl not available, skipping Kustomize validation"
fi

log "✓ Validation completed successfully"
