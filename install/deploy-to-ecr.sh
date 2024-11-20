#!/bin/bash

# Environment variable provided as the first argument
env=$1

# Frontend directory provided as the second argument
FRONTEND_DIR=$2

# Check if the environment variable is set
if [ -z "$env" ]; then
  echo "Environment is not specified. Please provide the environment as the first argument."
  exit 1
fi

# Check if the frontend directory is provided and exists
if [ -z "$FRONTEND_DIR" ] || [ ! -d "$FRONTEND_DIR" ]; then
  echo "Frontend directory is not specified or does not exist. Please provide the frontend directory as the second argument."
  exit 1
fi

current_dir=$(pwd)
# Log file path
LOGFILE="${current_dir}/${env}-deploy-to-ecr.log"

# Function to log messages to both console and log file
log() {
  echo "$(date): $1" | tee -a "${LOGFILE}"
}

# Function to prompt the user for input
prompt_for_aws_region() {
  read -p "Please enter the AWS region: " aws_region
  echo "${aws_region}"
}

# Attempt to get the current AWS region from the AWS CLI configuration
aws_region=$(aws configure get region)

# Check if the AWS region is set
if [ -z "${aws_region}" ]; then
  log "AWS region is not set in the AWS CLI configuration."
  aws_region=$(prompt_for_aws_region)
fi

# Log the detected or provided AWS region
log "Using AWS region: ${aws_region}"

# Attempt to get the AWS account number
AWS_ACCOUNT_NUMBER=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "${AWS_ACCOUNT_NUMBER}" ]; then
  log "Failed to fetch AWS account number. Exiting."
  exit 1
fi
log "Using AWS account number: ${AWS_ACCOUNT_NUMBER}"

# Construct ECR parameter
ECR_PARAMETER="${AWS_ACCOUNT_NUMBER}.dkr.ecr.${aws_region}.amazonaws.com"

# Get Params from TF Output
{
  ECR_REPO_NAME=$(jq -r '.ecr_repository_name.value' "../${env}/${env}-outputs.json")
  if [ -z "$ECR_REPO_NAME" ]; then
    log "ECR_REPO_NAME not found in ${env}/${env}-outputs.json. Please ensure the output file contains the required secret."
    exit 1
  fi
  log "ECR_REPO_NAME fetched: $ECR_REPO_NAME"
} || {
  log "Failed to fetch ECR_REPO_NAME from output file."
  exit 1
}

{
  ECS_CLUSTER_NAME=$(jq -r '.ecs_cluster_name.value' "../${env}/${env}-outputs.json")
  if [ -z "$ECR_REPO_NAME" ]; then
    log "ECS_REPO_NAME not found in ${env}/${env}-outputs.json. Please ensure the output file contains the required secret."
    exit 1
  fi
  log "ECS_REPO_NAME fetched: $ECS_CLUSTER_NAME"
} || {
  log "Failed to fetch ECS_CLUSTER_NAME from output file."
  exit 1
}

{
  ECS_SERVICE_NAME=$(jq -r '.ecs_service_name.value' "../${env}/${env}-outputs.json")
  if [ -z "$ECS_SERVICE_NAME" ]; then
    log "ECS_SERVICE_NAME not found in ${env}/${env}-outputs.json. Please ensure the output file contains the required secret."
    exit 1
  fi
  log "ECS_SERVICE_NAME fetched: $ECS_SERVICE_NAME"
} || {
  log "Failed to fetch ECS_SERVICE_NAME from output file."
  exit 1
}


# Attempt to authenticate to ECR
if aws ecr get-login-password --region "${aws_region}" | docker login --username AWS --password-stdin "${ECR_PARAMETER}"; then
  log "Successfully logged into ECR: ${ECR_PARAMETER}"
else
  log "Failed to log into ECR: ${ECR_PARAMETER}"
  exit 1
fi

# Make sure you can enter the FRONTEND_DIR
if ! cd "$FRONTEND_DIR"; then
  log "Failed to change directory to ${FRONTEND_DIR}. Exiting."
  exit 1
fi
log "Changed directory to ${FRONTEND_DIR}."

# Attempt to build Docker image
if docker build -t "${ECR_REPO_NAME}" . ; then
  log "Successfully built Docker image: ${ECR_REPO_NAME}"
else
  log "Failed to build Docker image: ${ECR_REPO_NAME}"
  exit 1
fi

# Attempt to tag Docker image
if docker tag "${ECR_REPO_NAME}:latest" "${ECR_PARAMETER}/${ECR_REPO_NAME}:latest"; then
  log "Successfully tagged Docker image: ${ECR_REPO_NAME}:latest"
else
  log "Failed to tag Docker image: ${ECR_REPO_NAME}:latest"
  exit 1
fi


# Get the SHA digest of the latest image
#image_sha=$(docker inspect --format='{{index .RepoDigests 0}}' "${ECR_REPO_NAME}:latest" | cut -d ':' -f 2)
#if [ -z "$image_sha" ]; then
#  log "Failed to get SHA digest for image: ${ECR_REPO_NAME}:latest"
#  exit 1
#fi
#log "SHA digest for image ${ECR_REPO_NAME}:latest is ${IMAGE_SHA}"
#
## Create a new tag with date and SHA
#DATE_SHA_TAG=$(date +%Y%m%d)-$IMAGE_SHA

#docker tag "${ECR_REPO_NAME}:latest" "${ECR_PARAMETER}/${ECR_REPO_NAME}:${DATE_SHA_TAG}"
#log "Tagged image with date-sha: ${ECR_REPO_NAME}:${DATE_SHA_TAG}"

# Continue with docker push or other steps...

# Attempt to push Docker image
if docker push "${ECR_PARAMETER}/${ECR_REPO_NAME}:latest"; then
  log "Successfully pushed Docker image to ECR: ${ECR_PARAMETER}/${ECR_REPO_NAME}:latest"
else
  log "Failed to push Docker image to ECR: ${ECR_PARAMETER}/${ECR_REPO_NAME}:latest"
  exit 1
fi

#if docker push "${ECR_PARAMETER}/${ECR_REPO_NAME}:${DATE_SHA_TAG}"; then
#  log "Successfully pushed Docker image to ECR: ${ECR_PARAMETER}/${ECR_REPO_NAME}:${DATE_SHA_TAG}"
#else
#  log "Failed to push Docker image to ECR: ${ECR_PARAMETER}/${ECR_REPO_NAME}:${DATE_SHA_TAG}"
#  exit 1
#fi



