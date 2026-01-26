module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.0"

  identifier = var.rds_config.instance_name

  # Engine Configuration
  engine               = "mysql"
  engine_version       = var.rds_config.engine_version
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = var.rds_config.instance_class

  # Storage Configuration
  allocated_storage     = var.rds_config.allocated_storage
  max_allocated_storage = var.rds_config.max_allocated_storage
  storage_type          = var.rds_config.storage_type
  # iops                  = var.rds_config.iops
  # storage_throughput    = var.rds_config.storage_throughput

  # Database Configuration
  db_name  = null  # Will be created manually
  username = "admin"
  manage_master_user_password = true

  # Network Configuration
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # Subnet Group
  create_db_subnet_group = true
  subnet_ids = values(aws_subnet.private)[*].id
  db_subnet_group_name = "${var.rds_config.instance_name}-subnet-group"
  db_subnet_group_use_name_prefix = false
  
  publicly_accessible = var.rds_config.publicly_accessible

  # Multi-AZ Configuration
  multi_az = var.rds_config.multi_az

  # Parameter Group
  create_db_parameter_group = true
  parameter_group_name = "${var.rds_config.instance_name}-parameter-group"
  parameter_group_use_name_prefix = false
  parameters = [
    {
      name  = "init_connect"
      value = "SET time_zone = 'Asia/Yangon';"
      apply_method = "immediate"
    }
  ]

  # Option Group
  create_db_option_group = true
  option_group_name = "${var.rds_config.instance_name}-option-group"
  option_group_use_name_prefix = false
  options = []  # No specific options needed for basic MySQL

  # Monitoring Configuration
  monitoring_interval    = var.rds_config.monitoring_interval
  monitoring_role_arn    = var.rds_config.monitoring_interval > 0 ? aws_iam_role.rds_monitoring.arn : null
  enabled_cloudwatch_logs_exports = var.rds_config.enabled_cloudwatch_logs_exports

  # Performance Insights
  # performance_insights_enabled          = var.rds_config.performance_insights_enabled
  # performance_insights_retention_period = var.rds_config.performance_insights_retention_period

  # Backup Configuration
  backup_retention_period = var.rds_config.backup_retention_period
  backup_window          = var.rds_config.backup_window
  copy_tags_to_snapshot  = var.rds_config.copy_tags_to_snapshot
  skip_final_snapshot    = true

  # Maintenance Configuration
  auto_minor_version_upgrade = var.rds_config.auto_minor_version_upgrade
  maintenance_window         = var.rds_config.maintenance_window

  # Deletion Protection
  deletion_protection = var.rds_config.deletion_protection

  # Disable Extended Support
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"

  tags = var.common_tags
}