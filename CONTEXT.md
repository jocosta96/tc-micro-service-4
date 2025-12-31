# Context: tc-micro-service-4

## Repository Purpose

This is an **Infrastructure as Code (IAC)** repository for a microservice ordering application. The repository was incrementally developed as part of a postgraduate program.

**Important Note**: This repository contains **only the infrastructure code** (Terraform configurations). The actual application code for the microservices is stored in separate repositories.

## Architecture Overview

The repository implements a microservices architecture on AWS using:
- **EKS (Elastic Kubernetes Service)** for container orchestration
- **API Gateway** with Lambda authorizer for API management
- **RDS/Database** modules for data persistence
- **VPC Networking** for service isolation
- **Kubernetes** for application deployment

## Repository Structure

### `/modules/` - Reusable Infrastructure Modules

Reusable Terraform modules that can be composed to build complete infrastructure stacks:

- **`api_gateway/`** - API Gateway configuration with Lambda authorizer
  - Creates REST API Gateway
  - Lambda function for token-based authorization
  - Integration with EKS load balancer
  - SSM parameter for secure token storage

- **`database/`** - Database infrastructure module
  - RDS instance configuration
  - Security groups and network access
  - Subnet groups for database placement
  - IAM roles and policies

- **`eks/`** - EKS cluster module
  - EKS cluster creation (version 1.34)
  - Node groups with auto-scaling
  - Security groups and access configuration
  - Load balancer integration

- **`k8s/`** - Kubernetes deployment module
  - ECR integration for container images
  - Kubernetes manifests (deployments, services, configmaps, secrets)
  - Horizontal Pod Autoscaler (HPA) configuration
  - IAM roles for service accounts (IRSA)

- **`network/`** - Networking infrastructure
  - VPC creation with CIDR blocks
  - Subnets across availability zones
  - Route tables and internet gateways
  - Network ACLs

### `/services/` - Microservice Infrastructure Stacks

Each microservice has its own Terraform configuration that composes the modules above:

- **`catalog/`** - Catalog microservice infrastructure
- **`order/`** - Order microservice infrastructure  
- **`payment/`** - Payment microservice infrastructure

Each service typically includes:
- Network module (VPC, subnets)
- Database module (RDS instance)
- EKS module (Kubernetes cluster)
- K8s module (application deployments)
- API Gateway module (external API access)

## Technology Stack

- **Infrastructure as Code**: Terraform
- **Cloud Provider**: AWS
- **Container Orchestration**: Kubernetes (EKS)
- **API Management**: AWS API Gateway
- **Database**: AWS RDS
- **Container Registry**: AWS ECR
- **Secrets Management**: AWS SSM Parameter Store

## State Management

Terraform state is stored in S3:
- Bucket: `tc-ordering-state-bucket`
- Region: `us-east-1`
- Each service has its own state file (e.g., `catalog-microservice.tfstate`)

## Key Design Patterns

1. **Modular Architecture**: Reusable modules promote DRY principles
2. **Service Isolation**: Each microservice has its own VPC and infrastructure stack
3. **Security**: Lambda authorizer for API authentication, security groups for network isolation
4. **Scalability**: Auto-scaling node groups and HPA for application scaling
5. **Observability**: EKS cluster logging enabled (API, audit, authenticator, controller, scheduler)

## Development Context

- **Program**: Postgraduate program
- **Project Type**: Incremental development project
- **Application**: Microservice ordering system
- **Code Location**: Application code is in separate repositories (not in this repo)

## Common Operations

### Deploying a Service
```bash
cd services/<service-name>
terraform init
terraform plan
terraform apply
```

### Module Development
Modules are designed to be reusable and configurable via variables. Each module follows standard Terraform module structure with:
- `main.tf` - Primary resources
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `providers.tf` - Provider configuration
- Additional files for IAM, network, secrets as needed

## Notes for Future Development

- Application code repositories are separate from this IAC repo
- Container images are referenced by name/tag (e.g., `jocosta96/soat-challenge:latest`)
- Each service can be deployed independently
- Network and security configurations are service-specific
- EKS clusters are created per-service for isolation

