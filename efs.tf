module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.0"

  # File System
  name           = var.efs_config.name
  creation_token = var.efs_config.name
  encrypted      = var.efs_config.encrypted

  performance_mode                = var.efs_config.performance_mode
  throughput_mode                 = var.efs_config.throughput_mode
  provisioned_throughput_in_mibps = var.efs_config.provisioned_throughput

  # Lifecycle Policy - Disabled
  lifecycle_policy = {}

  # Backup
  enable_backup_policy = var.efs_config.enable_backup

  # Mount Targets
  mount_targets = {
    for subnet_key in var.efs_config.subnet_keys : subnet_key => {
      subnet_id       = aws_subnet.private[subnet_key].id
      security_groups = [module.eks.cluster_primary_security_group_id]
    }
  }

  # Don't create new security group
  create_security_group = false

  # Access Points
  access_points = {
    for key, value in var.efs_access_points : key => {
      name = value.name
      posix_user = {
        gid = value.gid
        uid = value.uid
      }
      root_directory = {
        path = value.path
        creation_info = {
          owner_gid   = value.gid
          owner_uid   = value.uid
          permissions = value.permissions
        }
      }
    }
  }

  tags = var.common_tags
}