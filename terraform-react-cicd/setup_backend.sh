#!/bin/bash
# Script to create the necessary AWS backend resources for Terraform state.
set -e # Exit immediately if a command exits with a non-zero status

# --- Configuration (Must match main.tf backend block) ---
BUCKET_NAME="sidharth-terraform-cicd"
TABLE_NAME="sidharth-terraform-cicd-table"
AWS_REGION="us-east-1" # Match your AWS region

echo "--- 1. Creating S3 Backend Bucket: $BUCKET_NAME ---"
# Check if the bucket exists. If not, create it.
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
    echo "S3 bucket created successfully."
else
    echo "S3 bucket already exists."
fi

echo "--- 2. Creating DynamoDB Lock Table: $TABLE_NAME ---"
# Check if the table exists. If not, create it.
TABLE_STATUS=$(aws dynamodb describe-table --table-name $TABLE_NAME --region $AWS_REGION 2>&1 | grep -E 'TableStatus|ResourceNotFoundException')

if [[ $TABLE_STATUS == *"ResourceNotFoundException"* ]]; then
    aws dynamodb create-table \
        --table-name $TABLE_NAME \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region $AWS_REGION
    echo "DynamoDB table creation initiated. Waiting for activation..."
    # Wait until the table is active before proceeding
    aws dynamodb wait table-exists --table-name $TABLE_NAME --region $AWS_REGION
    echo "DynamoDB table is active."
else
    echo "DynamoDB table already exists."
fi

echo "--- Backend setup complete! ---"