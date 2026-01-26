# AWS Configuration
aws_region = "ap-southeast-1"
#aws_profile = "default"
#aws_profile = "terraform"

# VPC Configuration
vpc_config = {
  name = "devops-vpc"
  cidr = "10.100.0.0/20"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]

  # Public subnets configuration
  public_subnets = {
    "public-a" = {
      cidr = "10.100.0.0/27"
      name = "devops-subnet-public1-ap-southeast-1a"
      az   = "ap-southeast-1a"
    }
    "public-b" = {
      cidr = "10.100.7.0/27"
      name = "devops-subnet-public1-ap-southeast-1b"
      az   = "ap-southeast-1b"
    }
  }

  # Public route table configuration
  public_route_table_name = "devops-rtb-public1-ap-southeast-1a"

  # Private subnets configuration
  private_subnets = {
    "micro-a" = {
      cidr = "10.100.1.0/27"
      name = "devops-subnet-private1-micro-ap-southeast-1a"
      az   = "ap-southeast-1a"
      route_table_name = "devops-rtb-private1-micro-ap-southeast-1a"
    }
    "micro-b" = {
      cidr = "10.100.4.0/27"
      name = "devops-subnet-private1-micro-ap-southeast-1b"
      az   = "ap-southeast-1b"
      route_table_name = "devops-rtb-private1-micro-ap-southeast-1b"
    }
    "wso2-a" = {
      cidr = "10.100.2.0/27"
      name = "devops-subnet-private2-wso2-ap-southeast-1a"
      az   = "ap-southeast-1a"
      route_table_name = "devops-rtb-private2-wso2-ap-southeast-1a"
    }
    "wso2-b" = {
      cidr = "10.100.5.0/27"
      name = "devops-subnet-private2-wso2-ap-southeast-1b"
      az   = "ap-southeast-1b"
      route_table_name = "devops-rtb-private2-wso2-ap-southeast-1b"
    }
    "elk-a" = {
      cidr = "10.100.3.0/27"
      name = "devops-subnet-private3-elk-ap-southeast-1a"
      az   = "ap-southeast-1a"
      route_table_name = "devops-rtb-private3-elk-ap-southeast-1a"
    }
    "elk-b" = {
      cidr = "10.100.6.0/27"
      name = "devops-subnet-private3-elk-ap-southeast-1b"
      az   = "ap-southeast-1b"
      route_table_name = "devops-rtb-private3-elk-ap-southeast-1b"
    }
  }
  
  # NAT Gateway configuration
  nat_gateway_name = "devops-nat-public1-ap-southeast-1a"
  nat_eip_name = "devops-nat-eip"
  
  # IGW configuration
  igw_name = "devops-igw"
  
  # VPC DNS configuration
  enable_dns_hostnames = true
  enable_dns_support = true
}

vpc_endpoints = {
  s3 = {
    service = "s3"
    service_type = "Gateway"
    route_table_keys = ["micro-a"]
    name = "devops-vpce-s3"
  }
}

# EKS Configuration
eks_cluster_name = "devops-wso2-cluster"
eks_version      = "1.33"

# EKS Endpoint Access Configuration
eks_endpoint_config = {
  public_access  = true
  private_access = true
}

# EKS Node Groups - All three node groups as specified
node_groups = {
  micro = {
    name           = "micro-node-group"
    # instance_types = ["c5.xlarge"]
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    max_size       = 2
    desired_size   = 1
    disk_size      = 100
    ami_type       = "AL2023_x86_64_STANDARD"
    subnet_keys    = ["micro-a", "micro-b"]
    labels = {
      micro-node = "micro-node"
    }
  }
  wso2 = {
    name           = "wso2-node-group"
    # instance_types = ["c5.xlarge"]
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    max_size       = 2
    desired_size   = 1
    disk_size      = 100
    ami_type       = "AL2023_x86_64_STANDARD"
    subnet_keys    = ["wso2-a", "wso2-b"]
    labels = {
      wso2-apim = "wso2-apim"
      wso2      = "wso2"
      wso2-node = "wso2-node"
    }
  }
  # elk = {
  #   name           = "elk-node-group"
  #   instance_types = ["c5.xlarge"]
  #   capacity_type  = "ON_DEMAND"
  #   min_size       = 1
  #   max_size       = 3
  #   desired_size   = 1
  #   disk_size      = 100
  #   ami_type       = "AL2023_x86_64_STANDARD"
  #   subnet_keys    = ["elk-a", "elk-b"]
  #   labels = {
  #     elk-node = "elk-node"
  #   }
  # }
}

addon_versions = {
  kube_proxy               = "v1.33.3-eksbuild.4"
  coredns                  = "v1.12.1-eksbuild.2"
  eks_pod_identity_agent   = "v1.3.10-eksbuild.2"
  vpc_cni                  = "v1.20.4-eksbuild.2"
  cloudwatch_observability = "v4.8.0-eksbuild.1"
  aws_efs_csi_driver       = "v2.1.15-eksbuild.1"
  aws_ebs_csi_driver       = "v1.36.0-eksbuild.1"
}

# RDS Configuration
rds_config = {
  instance_name         = "devops-database"
  engine_version        = "8.0.42"
  # instance_class        = "db.t3.xlarge"
  instance_class        = "db.t3.micro"
  # allocated_storage     = 400
  allocated_storage     = 100
  max_allocated_storage = 1000
  # storage_type          = "gp3"
  storage_type         = "gp2"
  # iops                  = 12000
  # storage_throughput    = 800
  # multi_az              = true
  multi_az              = false
  publicly_accessible   = true
  backup_retention_period = 7
  backup_window         = "14:00-14:30"
  maintenance_window    = "Mon:19:23-Mon:19:53"
  deletion_protection   = true
  monitoring_interval   = 60
  # performance_insights_enabled = true
  # performance_insights_retention_period = 7
  enabled_cloudwatch_logs_exports = ["slowquery"]
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot = true
}

# Security Groups Configuration
security_groups = {
  eks_cluster_sg_name = "devops-wso2-cluster-sg"
  rds_sg_name         = "devops-database-sg"
}

# IAM Roles Configuration
iam_roles = {
  rds_monitoring_role_name = "rds-monitoring-role"
}

# EFS Configuration
efs_config = {
  name                   = "devops-efs"
  performance_mode       = "generalPurpose"
  throughput_mode        = "bursting"
  provisioned_throughput = 0
  encrypted              = false
  enable_backup          = false
  subnet_keys            = ["wso2-a", "wso2-b"]
}

efs_access_points = {
  wso2_log = {
    name        = "wso2-log"
    path        = "/wso2-log"
    uid         = 1000
    gid         = 1000
    permissions = "0755"
  }
  eservice = {
    name        = "eservice"
    path        = "/eservice"
    uid         = 1000
    gid         = 1000
    permissions = "0755"
  }
  elastic = {
    name        = "elastic"
    path        = "/elastic"
    uid         = 1000
    gid         = 1000
    permissions = "0755"
  }
  rabbitmq = {
    name        = "rabbitmq"
    path        = "/rabbitmq"
    uid         = 1000
    gid         = 1000
    permissions = "0755"
  }
  redis = {
    name        = "redis"
    path        = "/redis"
    uid         = 1000
    gid         = 1000
    permissions = "0755"
  }
}

# Common Tags
common_tags = {
  Environment = "testing"
  Project     = "POC"
  ManagedBy   = "terraform"
}