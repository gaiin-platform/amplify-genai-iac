#!/bin/bash

# Check if two arguments were provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <environment> <sls_directory>"
    exit 1
fi

# Assign the first and second parameters to env and SLS_DIR
env=$1
SLS_DIR=$2

# Define the path to the log file, which will be in the parent directory

current_dir=$(pwd)
LOG_FILE="${current_dir}/${env}-install.log"


YAML_FILE_NAME="${env}-var.yml"
# Local file path for the YAML file
LOCAL_YAML_FILE="./${YAML_FILE_NAME}"
# Relative path to the destination directory to check and where to update the file
DEST_DIR="${SLS_DIR}/var/"
# Destination file path for the YAML file
DEST_YAML_FILE="${DEST_DIR}${YAML_FILE_NAME}" 
# Path to the serverless compose log file
SERVERLESS_LOGFILE_PATH="$current_dir/${env}-serverless-compose.log"


echo "Current Directory: $current_dir"
echo "Log File: $LOG_FILE"
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

update_or_append() {
    local file="$1"
    local key="$2"
    local value="$3"

    # Use sed to update or append the file
    if grep -Fq "$key:" "$file"; then
        $SED_CMD "s#^$key:.*#$key: \"$value\"#" "$file"
        log_message "Updated $key in $file"
    else
        echo "$key: \"$value\"" >> "$file"
        log_message "Appended $key to $file"
    fi
}

# Function to log a message with a timestamp to LOG_FILE
log_message() {
    # Add a timestamp to the log message
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    # Combine the timestamp with the user-provided message
    local log_entry="${timestamp} - $1"
    # Append the log entry to the log file
    echo "$log_entry" >> "$LOG_FILE"
    # Optionally, echo log message to the console as well
    echo "$log_entry"
}

# Example usage within a script block
(
  cd "$SLS_DIR"
#  echo "Acitvating Python 3.11 Virtual Environment"
#  source .311venv/bin/activate
  echo $PWD
  echo $env


  cd "$SLS_DIR"
  
  # Run the serverless deploy command and redirect output to a log file using the current directory and env
  serverless deploy --stage $env --verbose >> "$current_dir/${env}-serverless-compose.log" 2>&1
  # Use log_message to log that the serverless deployment command has been executed
  log_message "serverless-compose deploy executed in $SLS_DIR"
#  deactivate
)
