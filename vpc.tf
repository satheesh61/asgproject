module "load_avg_demo_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
 # version = "4.0.1"  
  
  # VPC Basic Details
  name = "${local.asg_name}-vpc"
  cidr = local.vpc_cidr
  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  manage_default_route_table    = false

  # Database Subnets
#   database_subnets = local.database_subnets
#   create_database_subnet_group = true
#   create_database_subnet_route_table = true
  
  # NAT Gateways - Outbound Communication
  enable_nat_gateway = true
  single_nat_gateway = true

  # VPC DNS Parameters
  enable_dns_hostnames = true
  enable_dns_support   = true

  
  tags = local.common_tags
  vpc_tags = local.common_tags

  # Additional Tags to Subnets
  public_subnet_tags = {
    Type = "Public Subnets"
    "Name" = "${local.asg_name}-vpc-public-subnets"
            
  }
  private_subnet_tags = {
    Type = "private-subnets"
    "Name" = "${local.asg_name}-vpc-private-subnets"
  }

  database_subnet_tags = {
    Type = "database-subnets"
  }
  # Instances launched into the Public subnet should be assigned a public IP address.
  map_public_ip_on_launch = true
}