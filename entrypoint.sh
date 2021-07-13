#!/bin/bash

#This file retrieves GKE credentials and submits an Argo Workflow on K8s

set -e

############ Helper Functions ############

function check_env() {
    if [ -z $(eval echo "\$$1") ]; then
        echo "Variable $1 not found.  Exiting..."
        exit 1
    fi
}

function check_file_exists() {
    if [ ! -f $1 ]; then
        echo "File $1 was not found"
        echo "Here are the contents of the current directory:"
        ls
        exit 1
    fi
}

randomstring(){
    cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-z' | fold -w 7 | head -n 1
}

# Check the presence of all required environment variables and files
check_env "INPUT_ARGO_URL"
check_env "INPUT_APPLICATION_CREDENTIALS"
check_env "INPUT_PROJECT_ID"
check_env "INPUT_LOCATION_ZONE"
check_env "INPUT_CLUSTER_NAME"
check_env "INPUT_ARGO_SUBMIT_ARGS"
check_env "INPUT_NAMESPACE"
cd $GITHUB_WORKSPACE

# Allow SHA OVERRIDE
if [ ! -z "$INPUT_SHA" ]; then
    echo "SHA Override Provided: $SHA"
    SHA=$INPUT_SHA
else
    SHA=$GITHUB_SHA
fi

# Authenticate to GKE

# Recover Application Credentials For GKE Authentication
echo "$INPUT_APPLICATION_CREDENTIALS" | base64 -d > /tmp/account.json

# Use gcloud CLI to retrieve k8s authentication
gcloud auth activate-service-account --key-file=/tmp/account.json
gcloud config set project "$INPUT_PROJECT_ID"
gcloud container clusters get-credentials "$INPUT_CLUSTER_NAME" --zone "$INPUT_LOCATION_ZONE" --project "$INPUT_PROJECT_ID"

# Instantiate Argo Workflow

# If the optional argument PARAMETER_FILE_PATH is supplied, add additional -f <filename> argument to `argo submit` command
if [ ! -z "$INPUT_PARAMETER_FILE_PATH" ]; then
    echo "Parameter file path provided: $INPUT_PARAMETER_FILE_PATH"
    check_file_exists $INPUT_PARAMETER_FILE_PATH
    PARAM_FILE_CMD="-f $INPUT_PARAMETER_FILE_PATH"
else
    PARAM_FILE_CMD=""
fi

# Execute the command
ARGO_CMD="argo submit --namespace $INPUT_NAMESPACE $INPUT_ARGO_SUBMIT_ARGS $PARAM_FILE_CMD"
echo "executing command: $ARGO_CMD"
ARGO_CMD_OUT=$(eval "$ARGO_CMD")
echo "$ARGO_CMD_OUT"
WORKFLOW_NAME=$(echo "$ARGO_CMD_OUT" | grep 'Name:' | sed 's/ //g')

# Emit the outputs
echo "::set-output name=WORKFLOW_URL::$INPUT_ARGO_URL/$INPUT_NAMESPACE/$WORKFLOW_NAME"
