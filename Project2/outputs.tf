output "cluster_name" {
  description = "The name of the created EKS cluster."
  value       = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  description = "The API server endpoint for the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "connect_command" {
  description = "Run this command to connect to your EKS cluster using AWS CLI."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.eks_cluster.name}"
}

output "nginx_load_balancer_url" {
  description = "The URL to access Nginx (Wait 2 mins for DNS to propagate)"
  value       = kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.hostname
}