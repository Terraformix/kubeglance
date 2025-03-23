#!/bin/bash

FILES_TO_SCAN=("backend-deployment.yaml" "frontend-deployment.yaml")
PASSING_SCORE=4
HELM_RELEASE_NAME="kubeglance"
HELM_CHART_PATH="./helm/kubeglance"

log() {
    echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") "${@}"
}

log "🔍 Performing Kubesec scan - Static security analysis for Kubernetes manifests"
log "📂 Number of files to scan: ${#FILES_TO_SCAN[@]}"
echo "*****"

scan_manifest() {
    local file=$1

    log "📝 Scanning: $file"

    SCAN_RESULT=$(helm template "$HELM_RELEASE_NAME" "$HELM_CHART_PATH" --show-only "templates/$file" 2>/dev/null | docker run --rm -i kubesec/kubesec:latest scan /dev/stdin)

    if [[ -z "$SCAN_RESULT" || "$SCAN_RESULT" == "null" ]]; then
        log "❌ Error: Failed to render the Helm manifest or perform the scan."
        exit 1
    fi

    SCAN_SCORE=$(echo "$SCAN_RESULT" | jq -r '.[0].score // 0')
    SCAN_MESSAGE=$(echo "$SCAN_RESULT" | jq -r '.[0].message // "No message available"')

    log "📌 Scan Result: $SCAN_SCORE"

    if [[ "$SCAN_SCORE" -lt "$PASSING_SCORE" ]]; then
        log "❌ FAIL: Score is $SCAN_SCORE (threshold: $PASSING_SCORE)"
        log "⚠️ Scanning for $file has failed!"
        return 1 
    else
        log "✅ PASS: $SCAN_MESSAGE"
    fi

    echo "*****"
    return 0
}

overall_exit_code=0

for file in "${FILES_TO_SCAN[@]}"; do
    scan_manifest "$file" || overall_exit_code=1
done

log "Overall exit code: $overall_exit_code"

exit $overall_exit_code

