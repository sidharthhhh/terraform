provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "s3bucket" {
  bucket = "codewithsidharth-lovedevops-123"

  tags = {
    Name        = "Mys3bucket"
    Environment = "staging"
  }
}
