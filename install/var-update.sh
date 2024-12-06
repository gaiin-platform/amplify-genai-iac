#!/bin/bash

# Environment variable
env=$1
SLS_DIR=$2

LOGFILE="${env}-var-update.log"
exec > >(tee -a "$LOGFILE") 2>&1

log_message() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $message"
}

handle_error() {
    log_message "An error occurred on line $1"
    exit 1
}
trap 'handle_error $LINENO' ERR

# Ensure the environment and SLS_DIR variables are provided
if [[ -z "$env" || -z "$SLS_DIR" ]]; then
    log_message "Usage: $0 <env> <SLS_DIR>"
    exit 1
fi

# Path to the JSON file with Terraform outputs
OUTPUT_JSON_FILE="../${env}/${env}-outputs.json"
# The YAML file name to be created or updated
YAML_FILE_NAME="${env}-var.yml"
# Local file path for the YAML file
LOCAL_YAML_FILE="./${YAML_FILE_NAME}"
# Relative path to the destination directory to check and where to update the file
DEST_DIR="${SLS_DIR}/var/"
# Destination file path for the YAML file
DEST_YAML_FILE="${DEST_DIR}${YAML_FILE_NAME}"

echo "Local YAML file: $LOCAL_YAML_FILE"
echo "Destination Directory: $DEST_DIR"
echo "Destination YAML file: $DEST_YAML_FILE"

# Detect OS type for the sed in-place command
SED_CMD="sed -i"
if [[ "$(uname)" == "Darwin" ]]; then
    SED_CMD="sed -i ''"  # Use BSD sed syntax
elif [[ "$(uname)" == "Linux" ]]; then
    SED_CMD="sed -i"  # Use GNU sed syntax
fi

# Function to update or append a value in a YAML file
update_or_append() {
    local file="$1"
    local key="$2"
    local value="$3"
    # If the key is OAUTH_ISSUER_BASE_URL or OAUTH_AUDIENCE, prepend https:// to the value
    if [[ "$key" == "OAUTH_ISSUER_BASE_URL" || "$key" == "OAUTH_AUDIENCE" ]]; then
        value="https://${value}"
    fi
    # Use sed to update or append the file
    if grep -Fq "$key:" "$file"; then
        $SED_CMD "s#^$key:.*#$key: \"$value\"#" "$file"
        log_message "Updated $key in $file"
    else
        echo "$key: \"$value\"" >> "$file"
        log_message "Appended $key to $file"
    fi
}

# Attempt to get the AWS account ID and assign it to aws_account_id
aws_account_id=$(aws sts get-caller-identity --query "Account" --output text 2>>"$LOGFILE")

# Check if the command was successful
if [ $? -eq 0 ]; then
    log_message "Successfully retrieved AWS account ID: $aws_account_id"
else
    log_message "Failed to retrieve AWS account ID."
    exit 1
fi

# Create or update the local YAML file
if [[ ! -f "$LOCAL_YAML_FILE" ]]; then
    touch "$LOCAL_YAML_FILE"
fi

if [[ ! -f "$OUTPUT_JSON_FILE" ]]; then
    log_message "Output JSON file not found: $OUTPUT_JSON_FILE"
    exit 1
fi

domain="$(jq -r '.domain_name.value' "$OUTPUT_JSON_FILE")"
if [[ $? -ne 0 ]]; then
    log_message "Failed to parse domain_name from $OUTPUT_JSON_FILE"
    exit 1
fi

CUSTOM_API_DOMAIN="${env}-api.${domain}"

# Extract values from the JSON file and update the YAML files
update_or_append "$LOCAL_YAML_FILE" "CUSTOM_API_DOMAIN" "$CUSTOM_API_DOMAIN"
update_or_append "$LOCAL_YAML_FILE" "AWS_ACCOUNT_ID" "$aws_account_id"
update_or_append "$LOCAL_YAML_FILE" "COGNITO_USER_POOL_ID" "$(jq -r '.cognito_user_pool_id.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "OAUTH_ISSUER_BASE_URL" "$(jq -r '.cognito_user_pool_url.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "COGNITO_CLIENT_ID" "$(jq -r '.cognito_user_pool_client_id.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "VPC_ID" "$(jq -r '.vpc_id.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "VPC_CIDR" "$(jq -r '.vpc_cidr_block.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "OPENAI_API_KEY" "$(jq -r '.openai_api_key_secret_name.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "LLM_ENDPOINTS_SECRETS_NAME_ARN" "$(jq -r '.openai_endpoints_secret_arn.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "LLM_ENDPOINTS_SECRETS_NAME" "$(jq -r '.openai_endpoints_secret_name.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "SECRETS_ARN_NAME" "$(jq -r '.app_secrets_secret_arn.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "IDP_PREFIX" "$(jq -r '.provider.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "OAUTH_AUDIENCE" "$(jq -r '.domain_name.value' "$OUTPUT_JSON_FILE")"
update_or_append "$LOCAL_YAML_FILE" "HOSTED_ZONE_ID" "$(jq -r '.app_route53_zone_id.value' "$OUTPUT_JSON_FILE")"

# Extract private subnet IDs and update the respective fields
private_subnets=($(jq -r '.private_subnet_ids.value[]' "$OUTPUT_JSON_FILE"))
if [[ ${#private_subnets[@]} -lt 2 ]]; then
    log_message "Error: Less than two private subnets found in $OUTPUT_JSON_FILE"
    exit 1
fi

update_or_append "$LOCAL_YAML_FILE" "PRIVATE_SUBNET_ONE" "${private_subnets[0]}"
update_or_append "$LOCAL_YAML_FILE" "PRIVATE_SUBNET_TWO" "${private_subnets[1]}"


# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Update or create the destination YAML file
if [[ ! -f "$DEST_YAML_FILE" ]]; then
    touch "$DEST_YAML_FILE"
fi

update_or_append "$DEST_YAML_FILE" "CUSTOM_API_DOMAIN" "$CUSTOM_API_DOMAIN"
update_or_append "$DEST_YAML_FILE" "AWS_ACCOUNT_ID" "$aws_account_id"
update_or_append "$DEST_YAML_FILE" "COGNITO_USER_POOL_ID" "$(jq -r '.cognito_user_pool_id.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "OAUTH_ISSUER_BASE_URL" "$(jq -r '.cognito_user_pool_url.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "COGNITO_CLIENT_ID" "$(jq -r '.cognito_user_pool_client_id.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "VPC_ID" "$(jq -r '.vpc_id.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "VPC_CIDR" "$(jq -r '.vpc_cidr_block.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "PRIVATE_SUBNET_ONE" "${private_subnets[0]}"
update_or_append "$DEST_YAML_FILE" "PRIVATE_SUBNET_TWO" "${private_subnets[1]}"
update_or_append "$DEST_YAML_FILE" "OPENAI_API_KEY" "$(jq -r '.openai_api_key_secret_name.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "LLM_ENDPOINTS_SECRETS_NAME_ARN" "$(jq -r '.openai_endpoints_secret_arn.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "LLM_ENDPOINTS_SECRETS_NAME" "$(jq -r '.openai_endpoints_secret_name.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "SECRETS_ARN_NAME" "$(jq -r '.app_secrets_secret_arn.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "PANDOC_LAMBDA_LAYER_ARN" "$(jq -r '.pandoc_lambda_layer_arn.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "IDP_PREFIX" "$(jq -r '.provider.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "OAUTH_AUDIENCE" "$(jq -r '.domain_name.value' "$OUTPUT_JSON_FILE")"
update_or_append "$DEST_YAML_FILE" "HOSTED_ZONE_ID" "$(jq -r '.app_route53_zone_id.value' "$OUTPUT_JSON_FILE")"


echo "Updated values in ${LOCAL_YAML_FILE} based on ${OUTPUT_JSON_FILE}"
[[ -d "$DEST_DIR" ]] && log_message "Updated values in ${DEST_YAML_FILE} based on ${OUTPUT_JSON_FILE}" || log_message "Destination directory not present: ${DEST_DIR}"

# Cleanup command to remove specific unwanted files with a trailing quote
UNWANTED_LOCAL_FILE="${LOCAL_YAML_FILE}''"
UNWANTED_DEST_FILE="${DEST_YAML_FILE}''"

if [ -f "$UNWANTED_LOCAL_FILE" ]; then
    rm -f "$UNWANTED_LOCAL_FILE"
    log_message "Removed unintended file: $UNWANTED_LOCAL_FILE"
fi

if [ -f "$UNWANTED_DEST_FILE" ]; then
    rm -f "$UNWANTED_DEST_FILE"
    log_message "Removed unintended file: $UNWANTED_DEST_FILE"
fi