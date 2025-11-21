# codebuild.tf

# 1. The Main Builder (Builds the React App)
resource "aws_codebuild_project" "react_app_builder" {
  name          = "${var.project_name}-builder"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "5" # Minutes

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type = "CODEPIPELINE"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}"
      stream_name = "logs"
    }
  }
}

# 2. The Invalidator (Clears CloudFront Cache)
# This works around the CodePipeline API region bug by using the AWS CLI directly.
resource "aws_codebuild_project" "invalidator" {
  name          = "${var.project_name}-invalidator"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "5"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    image_pull_credentials_type = "CODEBUILD"
    
    # Pass the Distribution ID as an environment variable
    environment_variable {
      name  = "DISTRIBUTION_ID"
      value = aws_cloudfront_distribution.s3_distribution.id
    }
  }

  source {
    type = "CODEPIPELINE"
    # We define the build commands directly here (Inline Buildspec)
    buildspec = yamlencode({
      version = 0.2
      phases = {
        build = {
          commands = [
            "echo Invalidating CloudFront Cache...",
            "aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"
          ]
        }
      }
    })
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-invalidator"
      stream_name = "logs"
    }
  }
}