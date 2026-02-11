module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  environment          = var.environment
  public_subnets_cidr  = var.public_subnets
  private_subnets_cidr = var.private_subnets
  availability_zones   = var.availability_zones
  single_nat_gateway   = var.single_nat_gateway
}

module "security" {
  source = "./modules/security"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

module "iam" {
  source = "./modules/iam"

  environment = var.environment
}

module "alb" {
  source = "./modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security.alb_sg_id
  environment       = var.environment
  certificate_arn   = var.certificate_arn
}

locals {
  scaling_config = {
    low    = { min = 1, max = 3, desired = 1 }
    medium = { min = 2, max = 6, desired = 2 }
    high   = { min = 5, max = 20, desired = 5 }
  }

  asg_min     = var.traffic_type == "custom" ? var.asg_min_size : local.scaling_config[var.traffic_type].min
  asg_max     = var.traffic_type == "custom" ? var.asg_max_size : local.scaling_config[var.traffic_type].max
  asg_desired = var.traffic_type == "custom" ? var.asg_desired_capacity : local.scaling_config[var.traffic_type].desired
}

module "asg" {
  source = "./modules/asg"

  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  security_group_id         = module.security.ec2_sg_id
  target_group_arn          = module.alb.target_group_arn
  target_group_arn_suffix   = module.alb.target_group_arn_suffix
  alb_arn_suffix            = module.alb.alb_arn_suffix
  iam_instance_profile_name = module.iam.instance_profile_name
  environment               = var.environment
  instance_type             = var.instance_type
  min_size                  = local.asg_min
  max_size                  = local.asg_max
  desired_capacity          = local.asg_desired
  enable_spot_instances     = var.enable_spot_instances
}
