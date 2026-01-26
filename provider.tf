provider "aws" {
  region = var.aws_region
 # profile = var.aws_profile
  
  default_tags {
    tags = var.common_tags
  }
}


data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

terraform {
  backend "s3" {
    bucket         = "devops-testing-terraform-state-bucket" 
    key            = "eks/terraform.tfstate"      # store path
    region         = "ap-southeast-1"
    encrypt        = true
  }
}