This Terraform configuration creates AWS infrastructure for including VPC, EKS cluster, RDS database, and EFS storage using official AWS modules with comprehensive variable-based configuration.

## Architecture Overview

- **VPC**: Custom VPC (10.100.0.0/20) with 6 private + 2 public subnets across 2 AZs
- **EKS**: Kubernetes cluster v1.33 with 3 dedicated node groups (micro, wso2, elk)
- **RDS**: MySQL 8.0.42 with Multi-AZ, gp3 storage, and custom parameter group
- **EFS**: Shared file system with 5 access points for persistent storage
- **Security**: Dedicated security groups and IAM roles with least privilege
- **Networking**: Manual NAT Gateway, Internet Gateway, S3 VPC Endpoint

## File Structure

```
├── versions.tf         # Terraform and provider versions
├── provider.tf         # AWS provider configuration
├── variables.tf        # All input variables
├── terraform.tfvars    # Configuration values
├── vpc.tf              # VPC with manual subnets + VPC endpoints
├── security-groups.tf  # Security groups for EKS and RDS
├── iam.tf              # IAM roles for RDS monitoring
├── eks.tf              # EKS cluster with 3 node groups
├── alb-controller.tf   # alb ingress controller for EKS
├── rds.tf              # RDS MySQL with official module
├── efs.tf              # EFS with access points
├── outputs.tf          # Resource outputs
└── README.md           # This file
```

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- AWS permissions for VPC, EKS, RDS, EFS, IAM, and EC2 resources

## Configuration Structure

### VPC Configuration (Manual Implementation)
```hcl
vpc_config = {
  name = "cplus-mm-vpc"
  cidr = "10.100.0.0/20"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
  
  public_subnets = {
    "public-a" = { cidr, name, az }
    "public-b" = { cidr, name, az }
  }
  
  private_subnets = {
    "micro-a/b" = { cidr, name, az, route_table_name }
    "wso2-a/b"  = { cidr, name, az, route_table_name }
    "elk-a/b"   = { cidr, name, az, route_table_name }
  }
}
```
- **Manual Subnets**: Full control over subnet placement and naming
- **1:1 Route Tables**: Each private subnet has its own route table
- **Single NAT Gateway**: Cost-effective NAT strategy
- **S3 VPC Endpoint**: Gateway endpoint for S3 access

### EKS Configuration (3 Node Groups)
```hcl
node_groups = {
  micro = { c5.xlarge, ON_DEMAND, 1-2 nodes, micro-a/b subnets }
  wso2  = { c5.xlarge, ON_DEMAND, 1-2 nodes, wso2-a/b subnets }
  elk   = { c5.xlarge, ON_DEMAND, 1-3 nodes, elk-a/b subnets }
}
```
- **Dedicated Node Groups**: Workload isolation by node groups
- **AL2023**: Latest Amazon Linux 2023 AMI
- **Node Labels**: For pod scheduling and affinity
- **All Add-ons**: CoreDNS, VPC-CNI, EFS CSI, CloudWatch Observability

### RDS Configuration (Production Ready)
```hcl
rds_config = {
  instance_class = "db.t3.xlarge"
  storage = "gp3, 400GB, 12000 IOPS, 800 throughput"
  multi_az = true
  backup_retention = 7 days
  monitoring = "Enhanced + Performance Insights"
}
```
- **High Performance**: gp3 storage with optimized IOPS/throughput
- **High Availability**: Multi-AZ deployment
- **Monitoring**: Enhanced monitoring + Performance Insights
- **Security**: Private access only, custom parameter group

### EFS Configuration (Shared Storage)
```hcl
efs_config = {
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  access_points = ["wso2_log", "eservice", "elastic", "rabbitmq", "redis"]
}
```
- **5 Access Points**: Dedicated paths for different services
- **WSO2 Subnets**: Mount targets in wso2-a and wso2-b
- **EKS Integration**: Uses EKS cluster security group

## Deployment

1. **Initialize Terraform**:
```bash
terraform init
```

2. **Review Configuration**:
```bash
terraform plan
```

3. **Deploy Infrastructure**:
```bash
terraform apply
```

## What's Fully Automated

✅ **VPC**: Manual subnets, route tables, NAT gateway, VPC endpoints  
✅ **EKS**: Cluster with 3 node groups, all add-ons configured  
✅ **RDS**: MySQL instance with Multi-AZ, monitoring, backups  
✅ **EFS**: File system with 5 access points for services  
✅ **Security**: Security groups for EKS, RDS with proper rules  
✅ **IAM**: RDS monitoring role with required policies  

## Manual Steps Required

❌ **Database Creation**: RDS instance created but databases need manual creation  
❌ **EKS Access**: Configure kubectl access after deployment  
❌ **Application Deployment**: Kubernetes workloads deployment  
❌ **EFS Storage Classes**: Create Kubernetes storage classes for EFS  
❌ **SSL Certificates**: TLS certificate management  
❌ **Monitoring Dashboards**: CloudWatch dashboards and alerts  

## Post-Deployment Steps

### 1. Configure kubectl Access
```bash
aws eks update-kubeconfig --region ap-southeast-1 --name cplus-mm-wso2-cluster
```

### 2. Verify Node Groups
```bash
kubectl get nodes --show-labels
```

### 3. Create Databases
Connect to RDS instance and create required databases manually.

### 4. Deploy Applications
Deploy your applications to respective node groups using node selectors:
- **Micro services**: `micro-node=micro-node`
- **WSO2 services**: `wso2-node=wso2-node`, `wso2-apim=wso2-apim`
- **ELK stack**: `elk-node=elk-node`

### 5. Configure EFS Storage Classes
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: <EFS_FILE_SYSTEM_ID>
  directoryPerms: "0755"
```

## Configuration Management

### Version Updates
Update versions in `terraform.tfvars`:
```hcl
eks_version = "1.34"  # Update EKS version
addon_versions = {
  kube_proxy = "v1.34.0-eksbuild.1"  # Update addon versions
  # ...
}
```

### Node Group Scaling
Modify node group configuration:
```hcl
node_groups = {
  micro = {
    min_size = 2      # Scale up
    max_size = 4
    desired_size = 2
    # ...
  }
}
```

### RDS Configuration Changes
Update RDS settings:
```hcl
rds_config = {
  instance_class = "db.t3.2xlarge"  # Upgrade instance
  allocated_storage = 800           # Increase storage
  # ...
}
```

## Network Architecture

### Subnet Layout
```
VPC: 10.100.0.0/20 (4096 IPs)
├── Public Subnets
│   ├── public-a: 10.100.0.0/27  (32 IPs) - AZ-1a
│   └── public-b: 10.100.7.0/27  (32 IPs) - AZ-1b
└── Private Subnets
    ├── micro-a:  10.100.1.0/27  (32 IPs) - AZ-1a
    ├── micro-b:  10.100.4.0/27  (32 IPs) - AZ-1b
    ├── wso2-a:   10.100.2.0/27  (32 IPs) - AZ-1a
    ├── wso2-b:   10.100.5.0/27  (32 IPs) - AZ-1b
    ├── elk-a:    10.100.3.0/27  (32 IPs) - AZ-1a
    └── elk-b:    10.100.6.0/27  (32 IPs) - AZ-1b
```

### Security Groups
- **EKS Cluster**: Managed by EKS module
- **RDS**: Port 3306 from EKS cluster only
- **EFS**: Uses EKS cluster security group (NFS port 2049)

## Module Versions

- **AWS Provider**: `~> 6.0`
- **VPC Module**: `~> 6.5`
- **EKS Module**: `~> 21.0`
- **RDS Module**: `~> 7.0`
- **EFS Module**: `~> 1.0`

## Resource Outputs

The configuration provides comprehensive outputs:
- **VPC**: VPC ID, CIDR, subnet IDs
- **EKS**: Cluster ID, ARN, endpoint, OIDC provider
- **RDS**: Instance ID, endpoint, port
- **EFS**: File system ID, DNS name, access points

## Troubleshooting

### Common Issues
1. **EKS Access**: Ensure AWS CLI is configured with correct permissions
2. **Node Groups**: Check subnet availability and instance limits
3. **RDS**: Verify security group rules for database connectivity
4. **EFS**: Ensure mount targets are in correct subnets

### Useful Commands
```bash
# Check EKS cluster status
aws eks describe-cluster --name cplus-mm-wso2-cluster

# List node groups
aws eks list-nodegroups --cluster-name cplus-mm-wso2-cluster

# Check RDS instance
aws rds describe-db-instances --db-instance-identifier cplus-database

# Check EFS file system
aws efs describe-file-systems --file-system-id <EFS_ID>
```

## Cost Optimization

- **Single NAT Gateway**: Reduces NAT Gateway costs
- **gp3 Storage**: Cost-effective high-performance storage
- **On-Demand Instances**: Predictable costs for production workloads
- **EFS Bursting**: Cost-effective throughput mode

---

**Note**: This infrastructure setup follows AWS best practices and uses official Terraform modules for reliability and maintainability. All configurations are production-ready with proper security, monitoring, and backup strategies.
