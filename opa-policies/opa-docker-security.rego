package main

# Do not use 'latest' tag for base image
deny[msg] {
    input[i].Cmd == "from"
    val := split(input[i].Value[0], ":")
    contains(lower(val[1]), "latest")
    msg = sprintf("Line %d: do not use 'latest' tag for base images", [i])
}

deny[msg] {
    input[i].Cmd == "user"
    input[i].Value[0] == "root"
    msg = sprintf("Line %d: Containers must not run as root. Use a non-root user instead.", [i])
}

deny[msg] {
    input[i].Cmd == "run"
    contains(lower(input[i].Value[_]), "--privileged")
    msg = sprintf("Line %d: Do not use '--privileged' in RUN commands", [i])
}

deny[msg] {
    input[i].Cmd == "from"
    val := lower(input[i].Value[0])
    not startswith(val, "DEVSECOPS/")
    msg = sprintf("Line %d: Use only approved base images prefixed with 'DEVSECOPS/'", [i])
}