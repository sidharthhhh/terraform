# codepipeline.tf

# Define variables for artifact naming
locals {
  source_artifact_name = "SourceOutput"
  build_artifact_name  = "BuildOutput"
}

resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_artifacts.bucket
  }

  # --- STAGE 1: SOURCE (GitHub) ---
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = [local.source_artifact_name]

      configuration = {
        ConnectionArn    = var.codestar_connection_arn 
        FullRepositoryId = "${var.github_repo_owner}/${var.github_repo_name}"
        BranchName       = var.github_branch
        DetectChanges    = "true" 
      }
    }
  }

  # --- STAGE 2: BUILD (CodeBuild) ---
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = [local.source_artifact_name]
      output_artifacts = [local.build_artifact_name]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.react_app_builder.name
      }
    }
  }

  # --- STAGE 3: DEPLOY (S3 & Custom Invalidation) ---
  stage {
    name = "Deploy"
    
    # Action 1: Upload files to S3
    action {
      name            = "DeployToS3"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = [local.build_artifact_name]
      version         = "1"
      
      configuration = {
        BucketName    = aws_s3_bucket.frontend_hosting.bucket
        Extract       = "true"
      }
    }

    # Action 2: Invalidate CloudFront (Using CodeBuild Workaround)
    action {
      name            = "InvalidateCloudFront"
      category        = "Build" # Changed to 'Build' because we are using CodeBuild
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = [local.source_artifact_name] # Requires an input, even if unused
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.invalidator.name
      }
    }
  }
}