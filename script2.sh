#!/bin/bash
source ./common_functions.sh

SMILY='\U1F604'

print_color "red" "\033[33;5m${SMILY} ${SMILY} Welcome LTIMINDTREE ${SMILY} ${SMILY}\033[0m"

print_color "pink" "Login to source cluster"
login_to_source_cluster

read -p "$(print_color "pink" "Enter the application namespace from the above list that you want to migrate: ")" namespace

if check_namespace_exists "$namespace"; then
    print_color "green" "Namespace $namespace exists."
    
    timestamp=$(date +%d%m%Y%H%M%S)
    backupname="${namespace}_backup_${timestamp}"
    
    print_color "green" "Starting backup for namespace $namespace..."
    create_backup "$namespace" "$backupname"
    wait_for_backup "$backupname"

    restorename="${namespace}_restore_${timestamp}"
    read -p "$(print_color "pink" "Enter the namespace on which you want to migrate the application: ")" targetnamespace
    restore_namespace "$restorename" "$backupname" "$namespace" "$targetnamespace"

    print_color "green" "${namespace} namespace has been restored successfully in new namespace $targetnamespace ($restorename)"
else
    print_color "red" "$namespace namespace does not exist. Please run the script again with a valid namespace."
fi
