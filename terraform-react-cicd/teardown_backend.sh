#!/bin/bash
# Script to destroy the backend resources (S3 bucket and DynamoDB table).
set -e 

# --- Configuration (Must match setup_backend.sh) ---
BUCKET_NAME="sidharth-terraform-cicd"
TABLE_NAME="sidharth-terraform-cicd-table"
AWS_REGION="us-east-1"

echo "!!! WARNING: This script will delete the backend S3 bucket and DynamoDB table !!!"
read -p "Type 'DELETE' to confirm destruction: " CONFIRMATION

if [ "$CONFIRMATION" != "DELETE" ]; then
    echo "Destruction cancelled."
    exit 0
fi

echo "--- 1. Deleting DynamoDB Lock Table: $TABLE_NAME ---"
aws dynamodb delete-table --table-name $TABLE_NAME --region $AWS_REGION
echo "DynamoDB table deletion initiated."

echo "--- 2. Emptying and Deleting S3 Backend Bucket: $BUCKET_NAME ---"
# Empty the S3 bucket first, as delete-bucket only works on empty buckets.
aws s3 rm s3://$BUCKET_NAME --recursive || true

# Then delete the S3 bucket.
aws s3 rb s3://$BUCKET_NAME --force
echo "S3 bucket deleted."

echo "--- Backend resources destroyed successfully. ---"