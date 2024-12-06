#!/bin/bash

# Environment variable provided as the first argument
env=$1

# Define the log file path in the root directory where the script is run
LOG_FILE="$(pwd)/${env}-update-ecs-service.log"

CURRENT_DIR=$(pwd)

# Function to log a message with a timestamp to LOG_FILE
log_message() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_entry="${timestamp} - $1"
    echo "$log_entry" >> "$LOG_FILE"
    echo "$log_entry"
}

{
  ECS_CLUSTER_NAME=$(jq -r '.ecs_cluster_name.value' "../${env}/${env}-outputs.json")
  if [ -z "$ECS_CLUSTER_NAME" ]; then
    log_message "ECS_CLUSTER_NAME not found in ../${env}/${env}-outputs.json. Please ensure the output file contains the required secret."
    exit 1
  fi
  log_message "ECS_CLUSTER_NAME fetched: $ECS_CLUSTER_NAME"
} || {
  log_message "Failed to fetch ECS_CLUSTER_NAME from output file."
  exit 1
}

{
  ECS_SERVICE_NAME=$(jq -r '.ecs_service_name.value' "../${env}/${env}-outputs.json")
  if [ -z "$ECS_SERVICE_NAME" ]; then
    log_message "ECS_SERVICE_NAME not found in ../${env}/${env}-outputs.json. Please ensure the output file contains the required secret."
    exit 1
  fi
  log_message "ECS_SERVICE_NAME fetched: $ECS_SERVICE_NAME"
} || {
  log_message "Failed to fetch ECS_SERVICE_NAME from output file."
  exit 1
}

if aws ecs update-service --cluster "$ECS_CLUSTER_NAME" --service "$ECS_SERVICE_NAME" --force-new-deployment; then
    log_message "Successfully updated ECS service: $ECS_SERVICE_NAME in cluster: $ECS_CLUSTER_NAME"
else
    log_message "Failed to update ECS service: $ECS_SERVICE_NAME in cluster: $ECS_CLUSTER_NAME due to an error in update-service command."
    exit 1
fi