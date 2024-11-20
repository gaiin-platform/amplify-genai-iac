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
  # Run the serverless deploy command and redirect output to a log file using the current directory and env
  serverless deploy --stage $env --verbose >> "$current_dir/${env}-serverless-compose.log" 2>&1
  # Use log_message to log that the serverless deployment command has been executed
  log_message "serverless-compose deploy executed in $SLS_DIR"
#  deactivate
)
