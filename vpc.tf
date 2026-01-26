module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5"

  name = var.vpc_config.name
  cidr = var.vpc_config.cidr
  azs  = var.vpc_config.availability_zones

  # Public subnets
  public_subnets = values(var.vpc_config.public_subnets)[*].cidr

  public_subnet_names = values(var.vpc_config.public_subnets)[*].name

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }

  # Public Route Table
  public_route_table_tags = {
    Name = var.vpc_config.public_route_table_name
  }

  # Internet Gateway
  create_igw = true

  igw_tags = {
    Name = var.vpc_config.igw_name
  }

  # NAT Gateway Configuration - disable since we create manually (With resource)
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false
  enable_vpn_gateway     = false

  # DNS Configuration
  enable_dns_hostnames = var.vpc_config.enable_dns_hostnames
  enable_dns_support   = var.vpc_config.enable_dns_support

  # Disable ALL default route table creation
  manage_default_route_table            = false
  create_database_subnet_route_table    = false
  create_redshift_subnet_route_table    = false
  create_elasticache_subnet_route_table = false

  tags = var.common_tags
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = merge(var.common_tags, {
    Name = var.vpc_config.nat_eip_name
  })

  depends_on = [module.vpc]
  
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = module.vpc.public_subnets[0]
  
  tags = merge(var.common_tags, {
    Name = var.vpc_config.nat_gateway_name
  })
  
  depends_on = [module.vpc]
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = var.vpc_config.private_subnets
  
  vpc_id            = module.vpc.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  
  tags = merge(var.common_tags, {
    Name = each.value.name
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  })
}

# Route Tables for Private Subnets
resource "aws_route_table" "private" {
  for_each = var.vpc_config.private_subnets
  vpc_id   = module.vpc.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = each.value.route_table_name
  })
}

# Associate each private subnet with its own route table
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# VPC Endpoints
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.5"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    for key, config in var.vpc_endpoints : key => {
      service         = config.service
      service_type    = config.service_type
      route_table_ids = [for rt_key in config.route_table_keys : aws_route_table.private[rt_key].id]
      tags = {
        Name = config.name
      }
    }
  }

  tags = var.common_tags
}