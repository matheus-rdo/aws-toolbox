#!/bin/bash

# AWS SSM Port Forwarding Proxy Script
# This script establishes an SSM port forwarding session to an EC2 instance
# allowing you to access private resources in your VPC through the instance.

set -e

# Default values for variables (can be overridden by command-line arguments)
INSTANCE_ID=""
LOCAL_PORT=""
REMOTE_HOST=""
REMOTE_PORT=""
REGION=""
PROFILE=""

# Display usage information
function usage {
    echo "Usage: $0 -i INSTANCE_ID -l LOCAL_PORT -h REMOTE_HOST -p REMOTE_PORT [-r REGION] [-P PROFILE]"
    echo
    echo "Options:"
    echo "  -i INSTANCE_ID   EC2 instance ID to use as proxy"
    echo "  -l LOCAL_PORT    Local port to forward from"
    echo "  -h REMOTE_HOST   Remote host to connect to (e.g., RDS endpoint)"
    echo "  -p REMOTE_PORT   Remote port to connect to (e.g., 3306 for MySQL)"
    echo "  -r REGION        AWS region (default: from AWS config)"
    echo "  -P PROFILE       AWS CLI profile (default: default)"
    echo
    echo "Example: $0 -i i-0abc123def456 -l 5432 -h mydb.cluster-abc123.us-east-1.rds.amazonaws.com -p 5432"
    exit 1
}

# Check for AWS CLI and Session Manager Plugin
function check_prerequisites {
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI not found. Please install it first."
        exit 1
    fi

    # Check for Session Manager Plugin
    if ! aws ssm start-session --help &> /dev/null; then
        echo "Error: AWS Session Manager Plugin not found. Please install it."
        echo "Installation instructions: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
        exit 1
    fi
}

# Parse command line arguments
while getopts "i:l:h:p:r:P:" opt; do
    case $opt in
        i) INSTANCE_ID="$OPTARG" ;;
        l) LOCAL_PORT="$OPTARG" ;;
        h) REMOTE_HOST="$OPTARG" ;;
        p) REMOTE_PORT="$OPTARG" ;;
        r) REGION="$OPTARG" ;;
        P) PROFILE="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check required parameters
if [ -z "$INSTANCE_ID" ] || [ -z "$LOCAL_PORT" ] || [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_PORT" ]; then
    echo "Error: Missing required parameters."
    usage
fi

# Set optional parameters if provided
REGION_PARAM=""
if [ ! -z "$REGION" ]; then
    REGION_PARAM="--region $REGION"
fi

PROFILE_PARAM=""
if [ ! -z "$PROFILE" ]; then
    PROFILE_PARAM="--profile $PROFILE"
fi

# Check prerequisites
check_prerequisites

# Print connection information
echo "Establishing SSM port forwarding session..."
echo "Local port: $LOCAL_PORT > EC2 instance: $INSTANCE_ID > Remote: $REMOTE_HOST:$REMOTE_PORT"
echo "Press Ctrl+C to terminate the session."

# Start the SSM session
aws ssm start-session \
    $REGION_PARAM \
    $PROFILE_PARAM \
    --target "$INSTANCE_ID" \
    --document-name AWS-StartPortForwardingSession \
    --parameters "localPortNumber=$LOCAL_PORT,portNumber=$REMOTE_PORT,host=$REMOTE_HOST"
