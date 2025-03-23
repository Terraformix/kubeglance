package main

# Rule 1: Enforce Service type to be NodePort (or other types as needed)
deny[msg] {
    input.kind == "Service"
    not input.spec.type == "NodePort"
    msg = "Service type should be NodePort"
}

# Rule 2: Enforce containers in Deployments to run as non-root
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot == true
    msg = sprintf("Container '%s' in Deployment '%s' must not run as root. Use runAsNonRoot within container security context.", [container.name, input.metadata.name])
}

# Rule 3: Enforce the use of specific imagePullPolicy (e.g., "IfNotPresent")
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.imagePullPolicy == "IfNotPresent"
    msg = sprintf("Container '%s' in Deployment '%s' should use 'IfNotPresent' as imagePullPolicy.", [container.name, input.metadata.name])
}

# Rule 4: Enforce resource requests and limits in containers
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.cpu
    msg = sprintf("Container '%s' in Deployment '%s' should specify CPU resource requests.", [container.name, input.metadata.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.memory
    msg = sprintf("Container '%s' in Deployment '%s' should specify memory resource requests.", [container.name, input.metadata.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg = sprintf("Container '%s' in Deployment '%s' should specify CPU resource limits.", [container.name, input.metadata.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg = sprintf("Container '%s' in Deployment '%s' should specify memory resource limits.", [container.name, input.metadata.name])
}
