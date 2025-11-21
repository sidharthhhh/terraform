# iam.tf

# 1. IAM Role for AWS CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

# 2. IAM Role for AWS CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

# 3. CodeBuild/CodePipeline Policy
resource "aws_iam_policy" "pipeline_policy" {
  name        = "${var.project_name}-pipeline-policy"
  description = "Policy for CodeBuild/CodePipeline to manage S3, CloudFront, Logs, and Connections"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 🔑 NEW: Allow Pipeline to use the GitHub Connection
      {
        Action   = ["codestar-connections:UseConnection"]
        Effect   = "Allow"
        Resource = "*"
      },
      # CloudWatch Logs
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*" 
      },
      # S3 access
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*",
          aws_s3_bucket.frontend_hosting.arn,
          "${aws_s3_bucket.frontend_hosting.arn}/*",
        ]
      },
      # CodePipeline actions
      {
        Action   = ["codebuild:StartBuild", "codebuild:BatchGetBuilds"]
        Effect   = "Allow"
        Resource = [
           aws_codebuild_project.react_app_builder.arn,
           aws_codebuild_project.invalidator.arn # Permission for the new invalidator
        ]
      },
      # CloudFront Invalidation
      {
        Action   = ["cloudfront:CreateInvalidation", "cloudfront:GetDistribution"]
        Effect   = "Allow"
        Resource = aws_cloudfront_distribution.s3_distribution.arn
      }
    ]
  })
}

# Attach the policy to the roles
resource "aws_iam_role_policy_attachment" "codebuild_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.pipeline_policy.arn
}

resource "aws_iam_role_policy_attachment" "codepipeline_attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.pipeline_policy.arn
}