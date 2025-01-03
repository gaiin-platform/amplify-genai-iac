#!/bin/bash

# Environment variable provided as the first argument
env=$1

# Deployment directory provided as the second argument
DEP_DIR=$2
CURRENT_DIR=$(pwd)

# Log file path
LOG_FILE="${env}-base-prompts-ppt-templates.log"

# Function to log a message with a timestamp to LOG_FILE
log_message() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_entry="${timestamp} - $1"
    echo "$log_entry" >> "$LOG_FILE"
    echo "$log_entry"
}

# Path to the serverless compose log file
SERVERLESS_LOGFILE_PATH="${env}-serverless-compose.log"

# Parse the log file for the last occurrence of BasePromptsBucketOutput
BASE_PROMPTS_BUCKET=$(grep 'BasePromptsBucketOutput:' "${SERVERLESS_LOGFILE_PATH}" | tail -n 1 | awk '{ print $2 }' || true)

# If the BASE_PROMPTS_BUCKET is not set, prompt the user for it
if [ -z "${BASE_PROMPTS_BUCKET}" ]; then
  log_message "No BasePromptsBucketOutput found in ${SERVERLESS_LOGFILE_PATH}. Please check the deployment logs to acquire the BasePromptsBucketOutput."
  BASE_PROMPTS_BUCKET=$(prompt_for_value "BasePromptsBucketOutput" "This value can be found in CloudFormation in the outputs tab of the amplify-lambda stack")
fi

# Log the found or entered bucket name
log_message "BasePromptsBucketOutput (last occurrence) is set to: ${BASE_PROMPTS_BUCKET}"

# Upload the file to the S3 bucket, wrapped in an if statement
if aws s3 cp ../files/base.json s3://$BASE_PROMPTS_BUCKET/base.json; then
    log_message "File uploaded to s3://$BASE_PROMPTS_BUCKET/base.json successfully."
else
    log_message "File upload to s3://$BASE_PROMPTS_BUCKET/base.json failed."
fi

#Upload the templates for exporting to PPT

# Parse the log file for the last occurrence of ConverstionTemplatesBucketOutput
CONVERSTION_TEMPLATES_BUCKET=$(grep 'ConverstionTemplatesBucketOutput:' "${SERVERLESS_LOGFILE_PATH}" | tail -n 1 | awk '{ print $2 }' || true)

# If the CONVERSTION_TEMPLATES_BUCKET is not set, prompt the user for it
if [ -z "${CONVERSTION_TEMPLATES_BUCKET}" ]; then
  log_message "No ConverstionTemplatesBucketOutput found in ${SERVERLESS_LOGFILE_PATH}. Please check the deployment logs to acquire the ConverstionTemplatesBucketOutput."
  CONVERSTION_TEMPLATES_BUCKET=$(prompt_for_value "ConverstionTemplatesBucketOutput" "This value can be found in CloudFormation in the outputs tab of the amplify-lambda stack")
fi

# Log the found or entered bucket name
log_message "ConverstionTemplatesBucketOutput (last occurrence) is set to: ${CONVERSTION_TEMPLATES_BUCKET}"

# Upload the files from the templates folder to the S3 bucket
if aws s3 sync ../files/templates s3://${CONVERSTION_TEMPLATES_BUCKET}/templates/; then
    log_message "Templates folder uploaded to s3://${CONVERSTION_TEMPLATES_BUCKET}/templates/ successfully."
else
    log_message "Templates folder upload to s3://${CONVERSTION_TEMPLATES_BUCKET}/templates/ failed."
fi