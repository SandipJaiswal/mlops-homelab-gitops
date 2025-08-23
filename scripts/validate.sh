#!/bin/bash
set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Validating GitOps repository..."

# Check YAML syntax
log "Checking YAML syntax..."
find . -name "*.yaml" -o -name "*.yml" | while read -r file; do
    if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo "Invalid YAML: $file"
        exit 1
    fi
done

# Validate Kustomizations
log "Validating Kustomizations..."
find . -name "kustomization.yaml" | while read -r file; do
    dir=$(dirname "$file")
    if ! kubectl kustomize "$dir" > /dev/null 2>&1; then
        echo "Invalid Kustomization: $dir"
        exit 1
    fi
done

log "✓ Validation completed successfully"
