#!/bin/bash

php84() {
    local host_base="/home/ben/projects"
    local container_base="/var/www"

    local current_dir="$(pwd)"

    if [[ "$current_dir" != "$host_base"* ]]; then
        echo "Current directory is not inside $host_base"
        return 1
    fi

    local relative_path="${current_dir#$host_base}"
    local container_dir="${container_base}${relative_path}"

    sudo docker exec \
        -w "$container_dir" \
        homelab-php84 \
        "$@"
}
