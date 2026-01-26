provider "aws" {
  region = var.aws_region
 # profile = var.aws_profile
  
  default_tags {
    tags = var.common_tags
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
      command     = "aws"
    }
  }
}


terraform {
  backend "s3" {
    bucket         = "devops-testing-terraform-state-bucket" 
    key            = "eks/terraform.tfstate"      # store path
    region         = "ap-southeast-1"
    encrypt        = true
  }
}