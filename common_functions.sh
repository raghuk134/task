#!/bin/bash

print_color() {
    local color="$1"
    local text="$2"
    case "$color" in
        "red") echo -e "\e[31m$text\e[0m" ;;
        "pink") echo -e "\e[35m$text\e[0m" ;;
        "green") echo -e "\e[32m$text\e[0m" ;;
        *) echo "$text" ;;
    esac
}

login_to_source_cluster() {
    ../login/login-to-source-gke-cluster.sh
}

check_namespace_exists() {
    local namespace="$1"
    if kubectl get namespace "$namespace" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

create_backup() {
    local namespace="$1"
    local backupname="$2"
    velero backup create "$backupname" --include-namespaces "$namespace" --wait &> /dev/null
}

describe_backup() {
    local backupname="$1"
    velero describe backup "$backupname" &> /dev/null
}

restore_namespace() {
    local restorename="$1"
    local backupname="$2"
    local namespace="$3"
    local targetnamespace="$4"
    velero restore create "$restorename" --from-backup "$backupname" --namespace-mappings "$namespace:$targetnamespace" --wait &> /dev/null
}

wait_for_backup() {
    local backupname="$1"
    local max_retries=30
    local retry_count=0
    while [ $retry_count -lt $max_retries ]; do
        if kubectl get backup "$backupname" -n velero &> /dev/null; then
            echo -e "$(print_color "green" "Backup of namespace: $namespace ($backupname) has been created successfully.")"
            break
        else
            echo -e "$(print_color "yellow" "Waiting for backup $backupname to be complete... Retry $retry_count of $max_retries...")"
            velero get backups &> /dev/null
            sleep 5
        fi
        ((retry_count++))
    done
    if [ $retry_count -ge $max_retries ]; then
        echo -e "$(print_color "red" "Max retries reached. Backup $backupname not found.")"
        return 1
    fi
    return 0
}

print_symbols() {
    local symbol="$1"
    local count="$2"
    printf "%${count}s" | tr " " "$symbol"
}
