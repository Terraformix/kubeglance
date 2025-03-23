#!/bin/bash

# This script scans base Docker images with Trivy.
# Extracts base image from Dockerfiles and scans for vulnerabilities.

log() {
    echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") "${@}"
}

PASSING_LOW=10
PASSING_MEDIUM=5
PASSING_HIGH=5
PASSING_CRITICAL=5

get_docker_image_name() {
  dockerfile_path="$1"
  awk 'NR==1 {print $2}' "$dockerfile_path"
}

backend_dockerfile="./kubeglance-backend/Dockerfile"
frontend_dockerfile="./kubeglance-frontend/Dockerfile"

backend_image_name=$(get_docker_image_name "$backend_dockerfile")
frontend_image_name=$(get_docker_image_name "$frontend_dockerfile")

images=("$backend_image_name" "$frontend_image_name")

log "Performing Trivy security scans on Docker images..."

scan_image() {
  local image="$1"
  log "🔍 Starting scan for: $image"

  tmp_output=$(mktemp)

  # Run Trivy scan in the background and redirect output to a temp file
  docker run --rm -v "$(pwd):/root/.cache/" aquasec/trivy -q image --format json "$image" > "$tmp_output" &
  
  scan_pid=$!

  # Display progress indicator every 5 seconds
  while kill -0 "$scan_pid" 2>/dev/null; do
    log "⏳ Scanning $image... (still in progress)"
    sleep 10
  done

  scan_output=$(cat "$tmp_output")
  rm -f "$tmp_output"

  if [[ -z "$scan_output" ]]; then
    log "❌ Error: No scan output received! Skipping vulnerability checks."
    return 1
  fi

  count_low=$(log "$scan_output" | jq '[.Results[].Vulnerabilities[]? | select(.Severity=="LOW")] | length')
  count_medium=$(log "$scan_output" | jq '[.Results[].Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length')
  count_high=$(log "$scan_output" | jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length')
  count_critical=$(log "$scan_output" | jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length')

  log "✅ Scan complete for $image"
  log "Vulnerability summary for $image:"
  log "  LOW: $count_low (Allowed: $PASSING_LOW)"
  log "  MEDIUM: $count_medium (Allowed: $PASSING_MEDIUM)"
  log "  HIGH: $count_high (Allowed: $PASSING_HIGH)"
  log "  CRITICAL: $count_critical (Allowed: $PASSING_CRITICAL)"

  if [[ "$count_low" -gt "$PASSING_LOW" || "$count_medium" -gt "$PASSING_MEDIUM" || "$count_high" -gt "$PASSING_HIGH" || "$count_critical" -gt "$PASSING_CRITICAL" ]]; then
    log "❌ Vulnerability threshold exceeded for $image!"
    return 1
  else
    log "✅ Image $image passed the security scan."
    return 0
  fi
}

overall_exit_code=0
for image in "${images[@]}"; do
  scan_image "$image" || overall_exit_code=1
done

log "Overall exit code: $overall_exit_code"

exit $overall_exit_code
