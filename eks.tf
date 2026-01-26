resource "aws_iam_role" "eks_node_group" {
  name_prefix = "${var.eks_cluster_name}-node-group-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_node_group_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role" "ebs_csi_driver" {
  name_prefix = "${var.eks_cluster_name}-ebs-csi-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.eks_cluster_name
  kubernetes_version = var.eks_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = values(aws_subnet.private)[*].id

  # Cluster endpoint configuration
  endpoint_public_access  = var.eks_endpoint_config.public_access
  endpoint_private_access = var.eks_endpoint_config.private_access

  # OIDC Identity provider
  enable_irsa = true

  # Authentication mode
  authentication_mode = "API_AND_CONFIG_MAP"

  # Control plane logging - disabled
  enable_cluster_creator_admin_permissions = true

  # Use module default IAM roles
  create_iam_role = true
  iam_role_use_name_prefix = false

  # EKS Node Groups - Dynamic configuration
  eks_managed_node_groups = {
    for key, config in var.node_groups : key => {
      name            = config.name
      use_name_prefix = false
      instance_types  = config.instance_types
      capacity_type   = config.capacity_type
      
      min_size     = config.min_size
      max_size     = config.max_size
      desired_size = config.desired_size

      disk_size = config.disk_size
      ami_type  = config.ami_type

      # Use AWS managed launch template instead of custom
      use_custom_launch_template = false

      subnet_ids = [for subnet_key in config.subnet_keys : aws_subnet.private[subnet_key].id]

      # Use shared IAM role
      create_iam_role = false
      iam_role_arn    = aws_iam_role.eks_node_group.arn

      labels = config.labels

      tags = var.common_tags
    }
  }

  # Cluster add-ons with before_compute for critical networking
  addons = {
    coredns = {
      addon_version = var.addon_versions.coredns
    }
    eks-pod-identity-agent = {
      addon_version = var.addon_versions.eks_pod_identity_agent
      before_compute = true
    }
    kube-proxy = {
      addon_version = var.addon_versions.kube_proxy
    }
    vpc-cni = {
      addon_version = var.addon_versions.vpc_cni
      before_compute = true
    }
    amazon-cloudwatch-observability = {
      addon_version = var.addon_versions.cloudwatch_observability
      resolve_conflicts_on_create = "OVERWRITE"
    }
    aws-efs-csi-driver = {
      addon_version = var.addon_versions.aws_efs_csi_driver
      # Module will handle IRSA automatically
    }
    aws-ebs-csi-driver = {
      addon_version = var.addon_versions.aws_ebs_csi_driver
      pod_identity_association = [{
        role_arn        = aws_iam_role.ebs_csi_driver.arn
        service_account = "ebs-csi-controller-sa"
        namespace       = "kube-system"
      }]
    }
  }

  tags = var.common_tags
}