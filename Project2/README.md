Terraform AWS EKS Cluster & Nginx DeploymentThis project uses Terraform to build a complete, production-ready AWS EKS (Elastic Kubernetes Service) cluster from scratch. It includes all necessary networking (VPC, subnets, NAT Gateways) and deploys a sample Nginx application automatically.The key feature of this project is its "fire and forget" nature. You run one command (terraform apply), and it builds the entire stack, from the cloud infrastructure to the running application, outputting the final Load Balancer URL.Core Problem SolvedThis script automates the otherwise complex and time-consuming process of:Provisioning a secure, multi-AZ network.Configuring IAM roles for EKS.Waiting for the EKS control plane (15+ min).Bootstrapping and joining worker nodes.Configuring kubectl manually.Deploying an application with kubectl apply.This project condenses all those steps into a single, unified Terraform operation.Technology StackTerraform: Infrastructure as Code tool.AWS:VPC: Isolated cloud network.Subnets: Public (for LBs) and Private (for nodes).Internet Gateway & NAT Gateway: For public and private internet access.EKS: The managed Kubernetes control plane.EC2: The worker nodes (Managed Node Group).ELB: The Classic Load Balancer created by the K8s service.Kubernetes:kubernetes Terraform provider for deploying apps.nginx Deployment & LoadBalancer Service.File Structure.
├── main.tf           # Core AWS resources (VPC, EKS Cluster, Node Group)
├── nginx.tf          # Kubernetes resources (Nginx Deployment, Service)
├── providers.tf      # Declares AWS and Kubernetes providers
├── variables.tf      # Input variables (region, cluster_name, instance_type)
└── outputs.tf        # Outputs (cluster_endpoint, load_balancer_url)
🚀 How to UsePrerequisitesTerraform CLI installed.AWS CLI installed and configured (run aws configure).1. Initialize ProvidersSince this project uses both the aws and kubernetes providers, you must initialize them:terraform init
2. Deploy the StackThis one command will build everything. It will take 15-20 minutes, mostly while waiting for AWS to provision the EKS control plane.terraform apply --auto-approve
3. See the OutputsWhen finished, Terraform will output the key information:Apply complete! Resources: 24 added, 0 changed, 0 destroyed.

Outputs:

cluster_endpoint = "https://<...>.gr7.us-east-1.eks.amazonaws.com"
cluster_name = "my-eks-cluster"
connect_command = "aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster"
nginx_load_balancer_url = "http://<...>.us-east-1.elb.amazonaws.com"
S_Verification and Access1. Connect kubectl to your ClusterRun the command provided in the output to configure your local kubectl:aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster
2. Verify Pods are Running$ kubectl get pods
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-d9fdfdccc-8ltml    1/1     Running   0          5m
nginx-deployment-d9fdfdccc-k9jnv    1/1     Running   0          5m
3. Access the Nginx WebpageCopy the nginx_load_balancer_url from the output and paste it into your browser. You will see the "Welcome to nginx!" page.🧹 How to DestroyTo avoid AWS charges, destroy all resources when you are finished.terraform destroy --auto-approve
