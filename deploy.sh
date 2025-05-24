# Set your Google Cloud Project ID
export GOOGLE_CLOUD_PROJECT="local-dev-226505"

# Set your desired Google Cloud Location
export GOOGLE_CLOUD_LOCATION="asia-northeast1" # Example location

# Set the path to your agent code directory
export AGENT_PATH="./learning_agent" # Assuming capital_agent is in the current directory

# Set a name for your Cloud Run service (optional)
export SERVICE_NAME="prototype"

# Set an application name (optional)
export APP_NAME="prototype"

adk deploy cloud_run \
	--project=$GOOGLE_CLOUD_PROJECT \
	--region=$GOOGLE_CLOUD_LOCATION \
	--with_ui \
	$AGENT_PATH
