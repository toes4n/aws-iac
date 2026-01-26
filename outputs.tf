# VPC Outputs
output "vpc_name" {
  description = "Name of the VPC"
  value       = var.vpc_config.name
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "subnet_names" {
  description = "List of all subnet names"
  value = concat(
    values(var.vpc_config.public_subnets)[*].name,
    values(var.vpc_config.private_subnets)[*].name
  )
}

output "igw_names" {
  description = "List of Internet Gateway names"
  value       = [var.vpc_config.igw_name]
}

output "nat_names" {
  description = "List of NAT Gateway names"
  value       = [var.vpc_config.nat_gateway_name]
}

output "vpce_names" {
  description = "List of VPC Endpoint names"
  value       = values(var.vpc_endpoints)[*].name
}

# EKS Outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks.cluster_status
}

output "eks_cluster_version" {
  description = "Version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "eks_node_groups" {
  description = "EKS node groups with names and statuses"
  value = {
    for k, ng in module.eks.eks_managed_node_groups : k => {
      name   = ng.node_group_id
      status = ng.node_group_status
    }
  }
}

output "eks_addon_names" {
  description = "List of EKS add-on names"
  value       = keys(module.eks.cluster_addons)
}

# RDS Outputs
output "rds_instance_name" {
  description = "RDS instance identifier"
  value       = module.rds.db_instance_identifier
}

output "rds_instance_status" {
  description = "RDS instance status"
  value       = module.rds.db_instance_status
}

output "rds_engine_version" {
  description = "RDS engine version"
  value       = module.rds.db_instance_engine_version_actual
}

# EFS Outputs
output "efs_file_system_name" {
  description = "EFS file system name"
  value       = var.efs_config.name
}

output "efs_access_point_names" {
  description = "List of EFS access point names"
  value       = [for ap_key, ap in var.efs_access_points : ap.name]
}