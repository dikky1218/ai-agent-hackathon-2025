#!/bin/bash

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    source .env
else
    echo "Warning: .env file not found. Using default values."
fi

# Set your Google Cloud Project ID
export GOOGLE_CLOUD_PROJECT="local-dev-226505"

# Set your desired Google Cloud Location
export GOOGLE_CLOUD_LOCATION="asia-northeast1" # Example location

# Set the path to your agent code directory
# export AGENT_PATH="./learning_agent" # Assuming capital_agent is in the current directory

# Set a name for your Cloud Run service (optional)
# export SERVICE_NAME="prototype"

# Set an application name (optional)
# export APP_NAME="prototype"

# adk deploy cloud_run \
# 	--project=$GOOGLE_CLOUD_PROJECT \
# 	--region=$GOOGLE_CLOUD_LOCATION \
# 	--with_ui \
# 	$AGENT_PATH

# Build environment variables string for Cloud Run
ENV_VARS="GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT,GOOGLE_CLOUD_LOCATION=$GOOGLE_CLOUD_LOCATION,GOOGLE_GENAI_USE_VERTEXAI=false"

# Add ALLOWED_ORIGINS if it's defined in .env
if [ ! -z "$ALLOWED_ORIGINS" ]; then
    ENV_VARS="$ENV_VARS,ALLOWED_ORIGINS=$ALLOWED_ORIGINS"
    echo "Using ALLOWED_ORIGINS: $ALLOWED_ORIGINS"
else
    echo "ALLOWED_ORIGINS not set. Will use default '*' in application."
fi

if [ -z "$GOOGLE_API_KEY" ]; then
    echo "GOOGLE_API_KEY not set. Please set GOOGLE_API_KEY in .env file."
    exit 1
else
    ENV_VARS="$ENV_VARS,GOOGLE_API_KEY=$GOOGLE_API_KEY"
    echo "Using GOOGLE_API_KEY: ..."
fi



gcloud run deploy prototype \
--source . \
--region $GOOGLE_CLOUD_LOCATION \
--project $GOOGLE_CLOUD_PROJECT \
--allow-unauthenticated \
--set-env-vars="$ENV_VARS"