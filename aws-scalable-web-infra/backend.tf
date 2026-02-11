# NOTE: The S3 bucket and DynamoDB table must be created manually before initializing
# e.g., aws s3 mb s3://my-terraform-state-bucket-unique-123
#       aws dynamodb create-table --table-name terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

terraform {
  # backend "s3" {
  #   bucket         = "CHANGE_ME_TO_YOUR_UNIQUE_BUCKET_NAME"
  #   key            = "aws-scalable-web-infra/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}
