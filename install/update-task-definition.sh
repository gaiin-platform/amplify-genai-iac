#!/bin/bash

# Environment variable provided as the first argument
env=$1

# Deployment directory provided as the second argument
DEP_DIR=$2
CURRENT_DIR=$(pwd)

# Log file path
LOGFILE="${env}-update-task-definition.log"

# Path to the serverless compose log file
SERVERLESS_LOGFILE_PATH="${env}-serverless-compose.log"

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $message" | tee -a "$LOGFILE"
}

# Function to prompt the user for input
prompt_for_value() {
  local var_name=$1
  local prompt_message=$2
  local user_input

  read -p "Enter the value for $var_name. $prompt_message : " user_input
  echo "${user_input}"
}

# Ensure the environment variable is set
if [ -z "$env" ]; then
  log_message "The 'env' variable is not set. Please provide the environment as an argument."
  exit 1
fi

log_message "Updating variables secrets for environment: $env"


# Parse the log file for the last occurrence of ChatLambdaFunctionUrl
CHAT_ENDPOINT_URL=$(grep 'ChatLambdaFunctionUrl:' "${SERVERLESS_LOGFILE_PATH}" | tail -n 1 | awk '{ print $2 }' || true)

# If the CHAT_ENDPOINT_URL is not set, prompt the user for it
if [ -z "${CHAT_ENDPOINT_URL}" ]; then
  log_message "No ChatLambdaFunctionUrl found in ${SERVERLESS_LOGFILE_PATH}. Please check the deployment logs to acquire the ChatLambdaFunctionUrl."
  CHAT_ENDPOINT_URL=$(prompt_for_value "ChatLambdaFunctionUrl" "This value can be found in Cloudformation in the outputs tab of the amplify-js stack")
fi

log_message "ChatLambdaFunctionUrl (last occurrence) is set to: ${CHAT_ENDPOINT_URL}"

{
  CUSTOM_API_DOMAIN=$(grep 'CUSTOM_API_DOMAIN' "${env}-var.yml" | awk -F': ' '{ gsub(/^[ \t]*|[ \t]*$/,"",$2); gsub(/^"|"$/,"",$2); print $2 }')
  if [ -z "$CUSTOM_API_DOMAIN" ]; then
    log_message "CUSTOM_API_DOMAIN not found in ${env}-var.yml. Please ensure the variable is defined in the YAML file."
    exit 1
  fi
  log_message "Read CUSTOM_API_DOMAIN from YAML file: $CUSTOM_API_DOMAIN"
} || {
  log_message "Failed to read CUSTOM_API_DOMAIN from YAML file."
  exit 1
}

# Prepend https:// and append / to the CUSTOM_API_DOMAIN
API_BASE_URL="https://$CUSTOM_API_DOMAIN"
log_message "API_BASE_URL constructed: $API_BASE_URL"

# Fetch COGNITO_USER_DOMAINfrom the JSON output file
USER_POOL_DOMAIN=$(jq -r '.user_pool_domain.value' "../${env}/${env}-outputs.json")
if [ -z "$USER_POOL_DOMAIN" ]; then
  log_message "USER_POOL_DOMAIN not found in ../${env}/${env}-outputs.json. Please ensure the output file contains the required ID."
  exit 1
fi
log_message "USER_POOL_DOMAIN fetched: $USER_POOL_DOMAIN"

# Construct COGNITO_DOMAIN
COGNITO_DOMAIN="https://$USER_POOL_DOMAIN"
log_message "COGNITO_DOMAIN constructed: $COGNITO_DOMAIN"


# Fetch COGNITO_USER_POOL_ID from the JSON output file
COGNITO_USER_POOL_URL=$(jq -r '.cognito_user_pool_url.value' "../${env}/${env}-outputs.json")
if [ -z "$COGNITO_USER_POOL_URL" ]; then
  log_message "COGNITO_USER_POOL_URL not found in ../${env}/${env}-outputs.json. Please ensure the output file contains the required ID."
  exit 1
fi
log_message "COGNITO_USER_POOL_URL fetched: $COGNITO_USER_POOL_URL"

# Prepend https:// and append / to the COGNITO_USER_POOL_URL
COGNITO_ISSUER="https://$COGNITO_USER_POOL_URL"
log_message "COGNITO_ISSUER constructed: $COGNITO_ISSUER"

# Read COGNITO_USER_POOL_CLIENT_SECRET from the JSON output file
COGNITO_USER_POOL_CLIENT_SECRET=$(jq -r '.cognito_user_pool_client_secret.value' "../${env}/${env}-outputs.json")
if [ -z "$COGNITO_USER_POOL_CLIENT_SECRET" ]; then
    log_message "COGNITO_USER_POOL_CLIENT_SECRET not found in ../${env}/${env}-outputs.json. Please ensure the output file contains the required secret."
    exit 1
fi
log_message "COGNITO_USER_POOL_CLIENT_SECRET fetched: *******"


# Read COGNITO_CLIENT_ID from the JSON output file
COGNITO_CLIENT_ID=$(jq -r '.cognito_user_pool_client_id.value' "../${env}/${env}-outputs.json")
if [ -z "$COGNITO_CLIENT_ID" ]; then
    log_message "COGNITO_CLIENT_ID not found in ../${env}/${env}-outputs.json. Please ensure the output file contains the required secret."
    exit 1
fi
log_message "COGNITO_CLIENT_ID fetched: "${COGNITO_CLIENT_ID}""

# Read SECRETS_ARN_NAME from the YAML file
{
    SECRETS_ARN_NAME=$(grep 'SECRETS_ARN_NAME' "${env}-var.yml" | awk -F': ' '{ gsub(/^[ \t]*|[ \t]*$/,"",$2); gsub(/^"|"$/,"",$2); print $2 }')
    log_message "SECRETS_ARN_NAME fetched: $SECRETS_ARN_NAME"
} || {
    log_message "Failed to read SECRETS_ARN_NAME from YAML file."
    exit 1
}

# Read OPENAI_API_KEY from the YAML file
{
    OPENAI_API_KEY_SECRET_NAME=$(grep 'OPENAI_API_KEY' "${env}-var.yml" | awk -F': ' '{ gsub(/^[ \t]*|[ \t]*$/,"",$2); gsub(/^"|"$/,"",$2); print $2 }')
    log_message "OPENAI_API_KEY_SECRET_NAME fetched: $OPENAI_API_KEY_SECRET_NAME"
} || {
    log_message "Failed to read OPENAI_API_KEY_SECRET_NAME from YAML file."
    exit 1
}

# Prompt the user for OpenAI API Key
log_message "Prompting user for OpenAI API Key."
{
    read -p "Please enter your OpenAI API Key: " OPENAI_API_KEY
} || {
    log_message "Failed to read OpenAI API Key input."
    exit 1
}

# Check if the provided OpenAI API Key is not empty
if [ -z "$OPENAI_API_KEY" ]; then
    log_message "No OpenAI API Key provided. Exiting."
    exit 1
fi

# Generate a random 16-char string for NEXTAUTH_SECRET
{
    NEXTAUTH_SECRET=$(openssl rand -hex 8)
    log_message "NEXTAUTH_SECRET generated: $NEXTAUTH_SECRET"
} || {
    log_message "Failed to generate NEXTAUTH_SECRET."
    exit 1
}

{
if [ -z "$OPENAI_API_KEY_SECRET_NAME" ]; then
    log_message "No OpenAI API Key Secret Name provided. Exiting."
    exit 1
fi

    aws secretsmanager update-secret --secret-id "$OPENAI_API_KEY_SECRET_NAME" --secret-string "$OPENAI_API_KEY"
    log_message "Updated AWS Secrets Manager with OpenAI API Key."
} || {
    log_message "Failed to update the OpenAI API Key in AWS Secrets Manager."
    exit 1
}

# Perform all checks up-front
log_message "Performing variable checks up-front."
if [ -z "$CHAT_ENDPOINT_URL" ] || [ -z "$COGNITO_ISSUER" ] || [ -z "$COGNITO_DOMAIN" ] ||  [ -z "$CUSTOM_API_DOMAIN" ] || [ -z "$COGNITO_USER_POOL_CLIENT_SECRET" ] || [ -z "$SECRETS_ARN_NAME" ] || [ -z "$COGNITO_CLIENT_ID" ]; then
    log_message "Failed to obtain the necessary values. Exiting."
    exit 1
fi

log_message "The current directory is: $(pwd)"
# Determine the appropriate `sed` command for macOS and Linux
if [[ "$(uname)" == "Darwin" ]]; then
    SED_CMD="sed -i ''"
else
    SED_CMD="sed -i"
fi

# Update the values in the terraform.tfvars file
{
  $SED_CMD "s|\(CHAT_ENDPOINT *= *\"\)[^\"]*\"|\1$CHAT_ENDPOINT_URL\"|g" "../${env}/terraform.tfvars"
  $SED_CMD "s|\(API_BASE_URL *= *\"\)[^\"]*\"|\1$API_BASE_URL\"|g" ../"${env}/terraform.tfvars"
  $SED_CMD "s|\(COGNITO_CLIENT_ID *= *\"\)[^\"]*\"|\1$COGNITO_CLIENT_ID\"|g" "../${env}/terraform.tfvars"
  $SED_CMD "s|\(COGNITO_ISSUER *= *\"\)[^\"]*\"|\1$COGNITO_ISSUER\"|g" "../${env}/terraform.tfvars"
  $SED_CMD "s|\(COGNITO_DOMAIN *= *\"\)[^\"]*\"|\1$COGNITO_DOMAIN\"|g" "../${env}/terraform.tfvars"

  log_message "Updated terraform.tfvars with CHAT_ENDPOINT, API_BASE_URL, COGNITO_CLIENT_ID and."

  # Search for desired_count and change it to 1 if it is set to 0
  $SED_CMD "s|\(desired_count *= *\)0|\11|g" "../${env}/terraform.tfvars"
  log_message "Checked and updated desired_count to 1 if it was set to 0."
} || {
  log_message "Failed to update terraform.tfvars file."
  exit 1
}

# Delete the terraform.tfvars'' file if it exists
if [ -f "${env}/terraform.tfvars''" ]; then
  rm "${env}/terraform.tfvars''"
  log_message "Deleted stray terraform.tfvars'' file."
fi

log_message "Applying Terraform to push the updated task definition to AWS."
  # Final Terraform apply
    
cd "$DEP_DIR" || exit 1
  if  terraform apply 2>&1 | tee -a "$LOGFILE"; then
    log_message "Task Definition update complete."
  else
    log_message "Failed to update the task definition."
    exit 1
  fi

cd "$CURRENT_DIR" || exit 1

# Fetch the existing secret value to merge with new values
{
  EXISTING_SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRETS_ARN_NAME" --query 'SecretString' --output text 2>/dev/null || echo '{}')
  if [ "$EXISTING_SECRET_JSON" = '{}' ]; then
    log_message "Existing secret is empty or not found. Creating a new JSON object."
  else
    log_message "Fetched existing secret for secret id $SECRETS_ARN_NAME."
  fi
} || {
  log_message "Failed to fetch the existing secret for secret id $SECRETS_ARN_NAME."
  exit 1
}
# Fetch the existing secret value to merge with new values
{
  EXISTING_SECRET_STRING=$(aws secretsmanager get-secret-value --secret-id "$SECRETS_ARN_NAME" --query 'SecretString' --output text 2>/dev/null || echo '{}')
  log_message "Fetched existing secret for secret id $SECRETS_ARN_NAME."
} || {
  log_message "Failed to fetch the existing secret for secret id $SECRETS_ARN_NAME."
  exit 1
}

# Convert fetched secret to JSON, ensuring it's properly formatted
EXISTING_SECRET_JSON=$(echo "$EXISTING_SECRET_STRING" | jq -c 'try fromjson catch {}')
if [ "$EXISTING_SECRET_JSON" = "" ]; then
  log_message "Fetched secret is empty or not a valid JSON object. Initializing an empty JSON object."
  EXISTING_SECRET_JSON='{}'
fi

# Merge the new secrets with existing secrets if both are valid JSON
NEW_SECRET=$(echo "$EXISTING_SECRET_JSON" | jq --arg cc "$COGNITO_USER_POOL_CLIENT_SECRET" --arg oapi "$OPENAI_API_KEY" --arg nas "$NEXTAUTH_SECRET" \
  '. + {COGNITO_CLIENT_SECRET: $cc, OPENAI_API_KEY: $oapi, NEXTAUTH_SECRET: $nas}')

# Ensure the merged secret is not empty
if [ -z "$NEW_SECRET" ] || [ "$NEW_SECRET" = "{}" ]; then
  log_message "The resulting new secret is empty. Exiting."
  exit 1
fi

log_message "Combined new secrets with existing ones."

# Update the AWS secret with the new combined JSON
{
  aws secretsmanager update-secret --secret-id "$SECRETS_ARN_NAME" --secret-string "$NEW_SECRET"
  log_message "Updated AWS Secrets Manager with COGNITO_USER_POOL_CLIENT_SECRET, OPENAI_API_KEY, and NEXTAUTH_SECRET."
} || {
  log_message "Failed to update the AWS Secret."
  exit 1
}

FILES=("secret.json" "params.json")

# Function to delete files
delete_files() {
    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then # Check if file exists
            echo "Deleting $file: $(date)"
            rm "$file"
            if [ $? -eq 0 ]; then
                echo "Successfully deleted $file: $(date)"
            else
                echo "Error deleting $file: $(date)"
            fi
        else
            echo "File $file does not exist: $(date)"
        fi
    done
}

