#!/bin/bash

log() {
    echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") "${@}"
}

FRONTEND_DOCKERFILE="./kubeglance-frontend/Dockerfile"
BACKEND_DOCKERFILE="./kubeglance-backend/Dockerfile"


FILES_TO_SCAN=("$BACKEND_DOCKERFILE" "$FRONTEND_DOCKERFILE")

POLICY_PATH="./opa-policies/opa-docker-security.rego"

if [[ ! -f "$POLICY_PATH" ]]; then
    log "❌ Policy file not found at $POLICY_PATH. Exiting."
    exit 1
fi

scan_dockerfile() {
    local dockerfile=$1
    local policy=$2

    log "🔍 Scanning Dockerfile: $dockerfile"

    # Run the OPA conftest scan and capture the exit code
    SCAN_RESULT=$(docker run --rm -v $(pwd):/project openpolicyagent/conftest test "$dockerfile" --policy "$policy")
   
    # Store the correct exit code before any other command runs, since we capture the output above, causing us to not get the exit code for the docker command
    local exit_code=$?

    log "Scan result: $SCAN_RESULT"


    # Check if the scan failed
    if [[ $exit_code -ne 0 ]]; then
        log "❌ Security scan failed for: $dockerfile"
        return 1
    fi

    log "✅ Scan completed for $dockerfile"
    echo "*****"
    return 0
}

overall_exit_code=0
for file in "${FILES_TO_SCAN[@]}"; do
    if [[ ! -f "$file" ]]; then
        log "❌ Dockerfile not found: $file. Skipping."
        continue
    fi

    scan_dockerfile $file "$POLICY_PATH"
    if [[ $? -ne 0 ]]; then
        overall_exit_code=1
    fi
done

if [[ $overall_exit_code -eq 0 ]]; then
    log "🎉 All scans completed successfully!"
else
    log "⚠️ Some scans failed."
fi

exit $overall_exit_code
