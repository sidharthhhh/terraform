output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.app.id
}

output "launch_template_latest_version" {
  description = "Latest version of launch template"
  value       = aws_launch_template.app.latest_version
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.web.id
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.app.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "how_it_works" {
  description = "Explanation of create_before_destroy behavior"
  value       = <<-EOT
    CREATE_BEFORE_DESTROY BEHAVIOR:
    
    Normal Destroy/Create Flow:
    1. Destroy old resource
    2. Create new resource
    Problem: Downtime between steps 1 and 2!
    
    Create_Before_Destroy Flow:
    1. Create new resource with temporary name
    2. Update references to point to new resource
    3. Destroy old resource
    Result: Zero downtime! ✅
    
    Try this:
    1. Note the current template ID
    2. Change var.app_version = "v2.0"
    3. Run terraform apply
    4. Watch Terraform create NEW template before destroying old one
  EOT
}

output "test_instructions" {
  description = "How to test create_before_destroy"
  value       = <<-EOT
    TEST INSTRUCTIONS:
    
    1. Initial apply:
       terraform apply
    
    2. Note the resource IDs:
       terraform output
    
    3. Make a change to trigger recreation:
       terraform apply -var="app_version=v2.0"
    
    4. Watch the plan carefully:
       - You'll see "+/~" (create_before_destroy)
       - NOT "-/+" (destroy_create)
    
    5. During apply, you'll see:
       - New resource created first
       - Old resource destroyed second
    
    6. Try without create_before_destroy:
       - Comment out the lifecycle block
       - Run terraform apply
       - You'll see "-/+" (destroy first - downtime!)
  EOT
}
