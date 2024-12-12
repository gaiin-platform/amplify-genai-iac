#!/bin/bash

# Ensure the environment variable 'env' is set
read -p "Enter the environment (dev/prod): " env

# Define the log file path in the root directory where the script is run
LOG_FILE="$(pwd)/${env}-install.log"

# Function to log a message with a timestamp to LOG_FILE
log_message() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_entry="${timestamp} - $1"
    echo "$log_entry" >> "$LOG_FILE"
    echo "$log_entry"
}

INSTALL_DIR="$(pwd)"


# Function to prompt user for directory paths
prompt_for_directories() {
    # Define the configuration file path using the environment variable
    CONFIG_FILE="${env}_directories.config"

    # Check if the configuration file exists
    if [ -f "$CONFIG_FILE" ]; then
        # Source the configuration file to load previous values
        source "$CONFIG_FILE"

        # Prompt for updating Serverless Backend Repository directory
        read -p "Serverless Backend Repository directory is currently set to '$SLS_DIR'. Do you want to update it? [y/N]: " update_sls
        if [[ "$update_sls" =~ ^[Yy]$ ]]; then
            read -p "Please enter the full directory path for the Serverless Backend Repository (amplify-genai-backend): " SLS_DIR
        fi

        # Prompt for updating Frontend Repository directory
        read -p "Frontend Repository directory is currently set to '$FRONTEND_DIR'. Do you want to update it? [y/N]: " update_frontend
        if [[ "$update_frontend" =~ ^[Yy]$ ]]; then
            read -p "Please enter the full directory path for the Frontend Repository (amplify-genai-frontend): " FRONTEND_DIR
        fi
    else
        # If the file doesn't exist, prompt for both directories
        read -p "Please enter the full directory path for the Serverless Backend Repository (amplify-genai-backend): " SLS_DIR
        read -p "Please enter the full directory path for the Frontend Repository (amplify-genai-frontend): " FRONTEND_DIR
    fi

    # Save the directories to the config file
    echo "SLS_DIR=\"$SLS_DIR\"" > "$CONFIG_FILE"
    echo "FRONTEND_DIR=\"$FRONTEND_DIR\"" >> "$CONFIG_FILE"

    echo "Configuration saved to $CONFIG_FILE"
}

prompt_for_directories

# Define the deployment directory based on the environment
DEP_DIR="../${env}"

# Log the set directories
log_message "Terraform deployment directory set to: $DEP_DIR"
log_message "Serverless Backend Repository directory set to: $SLS_DIR"
log_message "Frontend Repository directory set to: $FRONTEND_DIR"

# Check if the deployment directory exists
if [[ ! -d "$DEP_DIR" ]]; then
    log_message "Environment directory $DEP_DIR does not exist."
    exit 1
fi
read -p "Do you need to run 'terraform init' in the $env environment? (y/n): " run_init

cd "$DEP_DIR" || exit 1

if [[ "$run_init" == "y" ]]; then
    terraform init 2>&1 | tee -a "$LOG_FILE"
fi

read -p "Do you need to run 'terraform apply' in the $env environment? (y/n): " run_tf_apply

if [[ "$run_tf_apply" == "y" ]]; then
    log_message "Running Terraform apply in the $env environment."
    terraform apply 2>&1 | tee -a "$LOG_FILE"
    log_message "Terraform apply complete."

    # Prompt for the second apply only if the first apply was run
    read -p "Do you need to run 'terraform apply' again to correct any issues in the $env environment? (y/n): " run_tf_apply2

    if [[ "$run_tf_apply2" == "y" ]]; then
        log_message "Running Terraform apply again to correct any issues."
        terraform apply 2>&1 | tee -a "$LOG_FILE"
        log_message "Second terraform apply complete."
    fi
fi

terraform output -json > "${env}-outputs.json"
log_message "Terraform apply complete. Outputs have been saved to ${env}-outputs.json."

cd - || exit 1
log_message "Updating Serverless Framework Vars"

./var-update.sh "${env}" "${SLS_DIR}" 2>&1 | tee -a "$LOG_FILE"


# Prompt user to continue
read -rp "Do you want to continue with the installation of Serverless Framework? (y/n): " choice
case "$choice" in
    [Yy]* )
        # Note in install log about installing serverless framework
        log_message "Now Installing Serverless Framework"
        ./serverless-compose.sh "${env}" "${SLS_DIR}" 2>&1 | tee -a "$LOG_FILE"
        ;;
    [Nn]* )
        log_message "Serverless Framework installation skipped by user."
        ;;
    * )
        log_message "Invalid response."
        ;;
esac


# Ask the user if they want to run the update-task-definition.sh script
read -p "This will update the task definition and run Terraform Apply to push it to AWS. Do you wish to proceed?(y/n): " run_update_task

# Run update-task-definition.sh if the user agrees
if [[ "$run_update_task" == "y" ]]; then
    ./update-task-definition.sh "${env}" "${DEP_DIR}" 2>&1 | tee -a "$LOG_FILE"
    log_message "Task definition updated"

else
    log_message "Task definition update skipped by user."
fi

# Ask the user if they want to update the ECS service
read -p "Do you want add base prompts and ppt files to S3 (y/n): " prompts_ppt

# Run deploy-to-ecs.sh if the user agrees
if [[ "$prompts_ppt" == "y" ]]; then
    ./prompts-ppt.sh "${env}"  2>&1 | tee -a "$LOG_FILE"
    log_message "Base Prompts and PPT Files uploaded to S3."
else
    log_message "Deploy base prompts and ppt export files skipped by user."
fi



cd - || exit 1

log_message "Your current directory is $(pwd)."

cd "$INSTALL_DIR" || exit 1

log_message "You new directory is $(pwd)."

# Ask the user if they want to build the container and upload to ECR
read -p "Do you want to build the container and deploy it to ECR? (y/n): " deploy_to_ecr

# Run deploy-to-ecr.sh if the user agrees
if [[ "$deploy_to_ecr" == "y" ]]; then
    ./deploy-to-ecr.sh "${env}" "${FRONTEND_DIR}" 2>&1 | tee -a "$LOG_FILE"
    log_message "Container built and deployed to ECR."
else
    log_message "Deploy to ECR skipped by user."
fi


# Ask the user if they want to update the ECS service
read -p "Do you want to deploy the updated service to ECS? (y/n): " deploy_to_ecs

# Run deploy-to-ecs.sh if the user agrees
if [[ "$deploy_to_ecs" == "y" ]]; then
    ./update-ecs-service.sh "${env}"  2>&1 | tee -a "$LOG_FILE"
    log_message "Service Re-deployed in AWS."
else
    log_message "Deploy to ECS skipped by user."
fi

log_message "Installation complete. Please check the log file for details: $LOG_FILE"