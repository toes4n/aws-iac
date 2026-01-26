variable "aws_region" {
  description = "AWS region"
  type        = string
}

#variable "aws_profile" {
#  description = "AWS CLI profile name"
#  type        = string
#}

# VPC Configuration
variable "vpc_config" {
  description = "VPC configuration"
  type = object({
    name = string
    cidr = string
    availability_zones = list(string)
    public_subnets = map(object({
      cidr = string
      name = optional(string)
      az   = string
    }))
    private_subnets = map(object({
      cidr = string
      name = optional(string)
      az   = string
      route_table_name = optional(string)
    }))
    # NAT Gateway configuration
    nat_gateway_name = optional(string)
    nat_eip_name     = optional(string)
    # IGW configuration
    igw_name = optional(string)
    # Public route table configuration
    public_route_table_name = optional(string)
    # DNS configuration
    enable_dns_hostnames = bool
    enable_dns_support   = bool
  })
}

# VPC Endpoints Configuration
variable "vpc_endpoints" {
  description = "VPC endpoints configuration"
  type = map(object({
    service = string
    service_type = string
    route_table_keys = list(string)
    name = string
  }))
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "EKS cluster version"
  type        = string
}

# EKS Endpoint Access Configuration
variable "eks_endpoint_config" {
  description = "EKS cluster endpoint access configuration"
  type = object({
    public_access  = bool
    private_access = bool
  })
}

# EKS Node Groups Configuration
variable "node_groups" {
  description = "EKS node groups configuration"
  type = map(object({
    name           = string
    instance_types = list(string)
    capacity_type  = string
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    ami_type       = string
    subnet_keys    = list(string)
    labels         = map(string)
  }))
}

# RDS Configuration
variable "rds_config" {
  description = "RDS configuration"
  type = object({
    instance_name                         = string
    engine_version                        = string
    instance_class                        = string
    allocated_storage                     = number
    max_allocated_storage                 = number
    storage_type                          = string
    iops                                  = optional(number)
    storage_throughput                    = optional(number)
    multi_az                              = bool
    publicly_accessible                   = bool
    backup_retention_period               = number
    backup_window                         = optional(string)
    maintenance_window                    = string
    deletion_protection                   = bool
    monitoring_interval                   = number
    performance_insights_enabled          = optional(bool)
    performance_insights_retention_period = optional(number)
    enabled_cloudwatch_logs_exports       = list(string)
    auto_minor_version_upgrade            = bool
    copy_tags_to_snapshot                 = bool
  })
}

# Security Groups Configuration
variable "security_groups" {
  description = "Security groups configuration"
  type = object({
    eks_cluster_sg_name = string
    rds_sg_name         = string
  })
}

# IAM Configuration
variable "iam_roles" {
  description = "IAM roles configuration"
  type = object({
    rds_monitoring_role_name = string
  })
}

variable "addon_versions" {
  description = "EKS addon versions"
  type = object({
    kube_proxy               = string
    coredns                  = string
    eks_pod_identity_agent   = string
    vpc_cni                  = string
    cloudwatch_observability = string
    aws_efs_csi_driver       = string
    aws_ebs_csi_driver       = string
  })
}

# EFS Configuration
variable "efs_config" {
  description = "EFS configuration"
  type = object({
    name                    = string
    performance_mode        = string
    throughput_mode         = string
    provisioned_throughput  = number
    encrypted               = bool
    enable_backup           = bool
    subnet_keys             = list(string)
  })
}

variable "efs_access_points" {
  description = "EFS access points configuration"
  type = map(object({
    name        = string
    path        = string
    uid         = number
    gid         = number
    permissions = string
  }))
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
}