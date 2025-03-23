#!/bin/bash

log() {
    echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") "${@}"
}

BACKEND_DEPLOYMENT_MANIFEST="backend-deployment.yaml"
FRONTEND_DEPLOYMENT_MANIFEST="frontend-deployment.yaml"

FILES_TO_SCAN=("$BACKEND_DEPLOYMENT_MANIFEST" "$FRONTEND_DEPLOYMENT_MANIFEST")

HELM_CHART_PATH="./helm/kubeglance"

POLICY_PATH="./opa-conftest/policies/opa-k8s-security.rego"

if [[ ! -f "$POLICY_PATH" ]]; then
    log "❌ Policy file not found at $POLICY_PATH. Exiting."
    exit 1
fi

scan_k8s_manifest() {
    local file=$1
    log "🔍 Scanning Kubernetes manifest: $file"

    # Render the Helm template and save it to a temporary file
    helm_output=$(helm template "$HELM_RELEASE_NAME" "$HELM_CHART_PATH" --show-only "templates/$file" 2>/dev/null)
    local helm_exit_code=$?

    if [[ $helm_exit_code -ne 0 ]]; then
        log "❌ Error rendering the Helm template for $file"
        return 1
    fi

    # Save the rendered template to a temporary file
    temp_file="${file}-rendered.yaml"
    echo "$helm_output" > "$temp_file"

    docker run --rm -v $(pwd):/project openpolicyagent/conftest test "$temp_file" --policy "$POLICY_PATH"
    local scan_exit_code=$?
    
    # Remove the temporary rendered file
    rm "$temp_file"

    if [[ $scan_exit_code -ne 0 ]]; then
        log "❌ Conftest scan failed for $file"
        return 1
    fi

    log "✅ Scan completed for $file"
    echo "*****"
    return 0
}

overall_exit_code=0
for file in "${FILES_TO_SCAN[@]}"; do
    if [[ ! -f "$HELM_CHART_PATH/templates/$file" ]]; then
        log "❌ Kubernetes manifest not found: $file. Skipping."
        continue
    fi

    scan_k8s_manifest "$file"
    if [[ $? -ne 0 ]]; then
        overall_exit_code=1
    fi
done

if [[ $overall_exit_code -eq 0 ]]; then
    log "🎉 All scans completed successfully!"
else
    log "❌ Some scans failed."
fi

exit $overall_exit_code
