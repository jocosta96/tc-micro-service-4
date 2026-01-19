# TC Microservice 4 - Ordering System Infrastructure.

## Overview
This repository contains Terraform Infrastructure as Code (IaC) for a microservices-based ordering system deployed on AWS. The architecture follows a modular approach with separate services for catalog, order, and payment processing.

## Architecture

### Services
- **Catalog Service**: Product catalog management
- **Order Service**: Order processing and management  
- **Payment Service**: Payment processing

### Infrastructure Components
Each service deploys the following AWS resources:
- **EKS Cluster**: Kubernetes orchestration with auto-scaling
- **RDS PostgreSQL**: Database with private subnets
- **API Gateway**: REST API with Lambda authorizer
- **VPC**: Isolated network with public/private subnets
- **Network Load Balancer**: Internal load balancing
- **Bastion Host**: Secure access for debugging (catalog only)

## Project Structure

```
tc-micro-service-4/
├── modules/                    # Reusable Terraform modules
│   ├── api_gateway/           # API Gateway with Lambda authorizer
│   ├── bastion/               # Bastion host for secure access
│   ├── database/              # RDS PostgreSQL setup
│   ├── eks/                   # EKS cluster and node groups
│   ├── k8s/                   # Kubernetes manifests and ECR
│   └── network/               # VPC, subnets, routing
├── services/                  # Service-specific deployments
│   ├── catalog/               # Catalog microservice
│   ├── order/                 # Order microservice
│   └── payment/               # Payment microservice
└── .github/workflows/         # CI/CD pipelines
```

## Key Features

### Security
- Lambda-based API Gateway authorizer with token validation
- Private database subnets with no internet access
- Security groups with least-privilege access
- ECR pull-through cache for Docker Hub images
- SSM Parameter Store for secrets management

### Scalability
- Horizontal Pod Autoscaler (HPA) for automatic scaling
- EKS node groups with configurable scaling policies
- Network Load Balancer for high availability

### Monitoring
- CloudWatch observability addon
- Application health checks and probes
- Metrics server for resource monitoring

## Network Architecture

### Catalog Service (10.0.0.0/16)
- Public subnets: EKS nodes, bastion host
- Private subnets: RDS database
- Bastion host for secure database access

### Order Service (10.10.0.0/16)
- Public subnets: EKS nodes
- Private subnets: RDS database

### Payment Service (10.20.0.0/16)
- Public subnets: EKS nodes
- Private subnets: RDS database

## Prerequisites

### AWS Setup
- AWS CLI configured with appropriate credentials
- EC2 key pair created (referenced in terraform.tfvars)
- Docker Hub credentials stored in AWS Secrets Manager for ECR pull-through cache

### Required Tools
- Terraform >= 1.12.2
- kubectl
- AWS CLI
- Docker (for local development)

## Deployment

### State Management
- S3 backend for Terraform state
- State bucket: `tc-microservices-state-bucket`
- Separate state files per service

### Environment Variables
Required in GitHub Actions:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `AWS_DEFAULT_REGION`

### Service Deployment
Each service can be deployed independently:

```bash
cd services/catalog
terraform init
terraform plan
terraform apply
```

### CI/CD Workflows
- **State Bucket**: Creates S3 bucket for Terraform state
- **Infrastructure Deploy**: Deploys complete service infrastructure
- **Targeted Update**: Updates only application deployments

## Configuration

### Key Variables
- `allowed_ip_cidrs`: IP ranges for bastion/EKS API access
- `ssh_key_pair_name`: EC2 key pair for bastion access
- `service`: Service name (catalog/order/payment)

### Application Configuration
- Image: `jocosta96/soat-challenge:latest`
- Port: 8080
- Health endpoint: `/health`
- Basic auth credentials stored in Kubernetes secrets

## Database Configuration

### Connection Details
Stored in SSM Parameter Store:
- `/ordering-system/{service}/database/host`
- `/ordering-system/{service}/database/port`
- `/ordering-system/{service}/database/name`
- `/ordering-system/{service}/database/username`
- `/ordering-system/{service}/database/password`

### Access Methods
1. **Application**: Direct connection from EKS pods
2. **Development**: SSH tunnel through bastion host (catalog service only)

## Kubernetes Resources

### Core Components
- **Deployment**: Application pods with resource limits
- **Service**: ClusterIP service for internal communication
- **ConfigMap**: Non-sensitive configuration
- **Secret**: API credentials and sensitive data
- **HPA**: Auto-scaling based on CPU utilization
- **TargetGroupBinding**: NLB integration

### Resource Limits
- CPU: 250m request, 500m limit
- Memory: 128Mi request, 256Mi limit
- Auto-scaling: 1-5 replicas based on 30% CPU threshold

## Troubleshooting

### Common Issues
1. **EKS Access**: Ensure kubeconfig is updated after cluster creation
2. **Database Connection**: Verify security group rules and subnet configuration
3. **Image Pull**: Check ECR pull-through cache setup and Docker Hub credentials
4. **Load Balancer**: Verify target group health and security group rules

### Debug Access
For catalog service, use bastion host:
```bash
ssh -i ~/.ssh/aws_key_pair ec2-user@<bastion-ip>
kubectl get pods
```

### Logs and Monitoring
- CloudWatch Logs: EKS cluster logs
- Application logs: `kubectl logs -f deployment/<service-name>`
- Metrics: CloudWatch Container Insights

## Development Guidelines

### Code Changes
- Test all possibilities before implementing changes
- Minimize code modifications to reduce risk
- Eliminate all possibilities through testing before deeper investigation
- Follow the established module structure for consistency

### Infrastructure Updates
- Use targeted deployments for application-only changes
- Full infrastructure changes require complete redeployment
- Always validate changes in development environment first

## Security Considerations

### Access Control
- API Gateway requires valid authorization token
- Database access restricted to application and bastion security groups
- EKS API server access limited to specified IP ranges

### Secrets Management
- Database credentials auto-generated and stored in SSM
- Application secrets stored in Kubernetes secrets
- ECR credentials managed through AWS Secrets Manager

## Cost Optimization

### Instance Types
- EKS nodes: t3.small (production), t3.micro (bastion)
- RDS: db.t3.micro with 20GB storage
- Spot instances not used for stability

### Resource Management
- Auto-scaling prevents over-provisioning
- Resources have defined limits to prevent runaway costs
- Development environments can be torn down when not in use