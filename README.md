# NTC Implementation Blueprint - Connectivity

This repository is part of the **Nuvibit Terraform Collection (NTC) Implementation Blueprints** - a comprehensive reference implementation showcasing best practices for building enterprise-grade AWS platforms using NTC building blocks.


## 🎯 Overview

The NTC Implementation Blueprints provide a complete, production-ready example of how to structure and deploy AWS infrastructure using the [Nuvibit Terraform Collection](https://docs.nuvibit.com/ntc-library/). These blueprints are deployed in a dedicated customer-simulated AWS organization (`aws-c2-*`), demonstrating real-world multi-account architecture patterns and configurations.

### Key Characteristics

- **Best Practice Architecture**: Implements the [Nuvibit AWS Reference Architecture (NARA)](https://docs.nuvibit.com/whitepapers/nuvibit-aws-reference-architecture/) with battle-tested patterns
- **GitOps Workflow**: All infrastructure is managed through Git with automated CI/CD pipelines
- **Secure Authentication**: Uses OpenID Connect (OIDC) for secure, short-lived credentials
- **Modular Design**: Each repository manages a specific domain or AWS account
- **Production-Ready**: Demonstrates configurations suitable for enterprise deployments

## 📋 Purpose of This Repository

This repository (`aws-c2-connectivity`) manages the **Connectivity Account** and is responsible for:

- **Transit Gateway**: Centralized network hub for inter-VPC and hybrid connectivity
- **Centralized VPC Management**: Centralized VPCs with subnets and routing configurations
- **IP Address Management (IPAM)**: Centralized CIDR allocation and IP space management
- **DNS Infrastructure**: Route 53 hosted zones, resolver endpoints, and hybrid DNS
- **Direct Connect**: Dedicated network connections to on-premises infrastructure
- **VPN Connections**: Site-to-site VPN for secure hybrid connectivity
- **Multi-Region Networking**: Transit Gateway peering across AWS regions

### NTC Building Blocks Used

This repository leverages the following NTC building blocks:

- [**NTC Core Network**](https://docs.nuvibit.com/ntc-building-blocks/connectivity/ntc-core-network/) - Transit Gateway, VPN, Direct Connect
- [**NTC VPC**](https://docs.nuvibit.com/ntc-building-blocks/connectivity/ntc-vpc/) - Virtual Private Clouds and subnets
- [**NTC IPAM**](https://docs.nuvibit.com/ntc-building-blocks/connectivity/ntc-ipam/) - IP Address Management
- [**NTC Route53**](https://docs.nuvibit.com/ntc-building-blocks/connectivity/ntc-route53/) - DNS management
- [**NTC Parameters**](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-parameters/) - Cross-account parameter sharing and orchestration


## 🏗️ Complete Blueprint Architecture

The NTC Implementation Blueprints consist of multiple repositories, each managing a specific domain or AWS account:

### Core Management Repositories

#### 1. [aws-c2-mgmt-organizations](https://github.com/nuvibit-c2/aws-c2-mgmt-organizations)
**Purpose**: Foundation of the AWS organization  
**Manages**: AWS Organizations, OU structure, SCPs, service integrations, cross-account parameters  
**Building Blocks**: [NTC Organizations](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-organizations/), [NTC Guardrail Templates](https://docs.nuvibit.com/ntc-building-blocks/templates/ntc-guardrail-templates/), [NTC Parameters](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-parameters/)

#### 2. [aws-c2-mgmt-account-factory](https://github.com/nuvibit-c2/aws-c2-mgmt-account-factory)
**Purpose**: Automated AWS account provisioning and lifecycle management  
**Manages**: Account creation, baseline configuration, budget alerts, lifecycle automation  
**Building Blocks**: [NTC Account Factory](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-account-factory/), [NTC Account Baseline Templates](https://docs.nuvibit.com/ntc-building-blocks/templates/ntc-account-baseline-templates/), [NTC Account Lifecycle Templates](https://docs.nuvibit.com/ntc-building-blocks/templates/ntc-account-lifecycle-templates/), [NTC Parameters](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-parameters/)

#### 3. [aws-c2-mgmt-identity-center](https://github.com/nuvibit-c2/aws-c2-mgmt-identity-center)
**Purpose**: Centralized identity and access management  
**Manages**: AWS IAM Identity Center (SSO), permission sets, user/group assignments  
**Building Blocks**: [NTC Identity Center](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-identity-center/), [NTC Parameters](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-parameters/)

### Core Account Repositories

#### 4. [aws-c2-log-archive](https://github.com/nuvibit-c2/aws-c2-log-archive)
**Purpose**: Centralized logging and audit trail storage  
**Manages**: S3 buckets for CloudTrail, VPC Flow Logs, DNS Query Logs, GuardDuty, AWS Config  
**Building Blocks**: [NTC Log Archive](https://docs.nuvibit.com/ntc-building-blocks/security/ntc-log-archive/), [NTC Parameters](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-parameters/)

#### 5. [aws-c2-security](https://github.com/nuvibit-c2/aws-c2-security)
**Purpose**: Centralized security monitoring and compliance  
**Manages**: Security Hub, GuardDuty, Inspector, Config, IAM Access Analyzer, automation rules  
**Building Blocks**: [NTC Security Tooling](https://docs.nuvibit.com/ntc-building-blocks/security/ntc-security-tooling/), [NTC Parameters](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-parameters/)

#### 6. [aws-c2-connectivity](https://github.com/nuvibit-c2/aws-c2-connectivity) ← *You are here*
**Purpose**: Network infrastructure and connectivity  
**Manages**: Transit Gateway, VPCs, Route 53, IPAM, Direct Connect, VPN, multi-region peering  
**Building Blocks**: [NTC Core Network](https://docs.nuvibit.com/ntc-building-blocks/connectivity/ntc-core-network/), [NTC VPC](https://docs.nuvibit.com/ntc-building-blocks/connectivity/ntc-vpc/), [NTC IPAM](https://docs.nuvibit.com/ntc-building-blocks/connectivity/ntc-ipam/), [NTC Route53](https://docs.nuvibit.com/ntc-building-blocks/connectivity/ntc-route53/), [NTC Parameters](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-parameters/)

## 🚀 Deployment Workflow

All blueprint repositories follow a consistent GitOps workflow:

1. **Infrastructure as Code**: All configurations are version-controlled in Git
2. **Pull Request Workflow**: Changes are proposed via pull requests
3. **Automated Planning**: CI/CD pipeline runs `terraform plan` on pull requests
4. **Peer Review**: Changes are reviewed before merging
5. **Automated Deployment**: Merging to main triggers `terraform apply` via CI/CD
6. **OIDC Authentication**: Pipelines authenticate to AWS using OpenID Connect (no static credentials)

## 📚 Getting Started

### Prerequisites

1. **NTC Access**: Valid NTC subscription and access credentials
2. **AWS Account**: Dedicated Connectivity account created via NTC Account Factory
3. **CI/CD Pipeline**: Configured CI/CD tool (e.g., Spacelift, GitHub Actions, GitLab CI/CD)
4. **RAM Sharing**: AWS Resource Access Manager (RAM) sharing must be enabled in AWS Organizations for sharing Transit Gateways, IPAM pools, and VPC subnets

:::info
RAM sharing can be easily enabled via [NTC Organizations](https://docs.nuvibit.com/ntc-building-blocks/management/ntc-organizations/) by setting `enable_ram_sharing_in_organization` to true.
:::

### Deployment Order

The blueprint repositories should be deployed in the following order:

1. **aws-c2-mgmt-organizations**   (foundation setup)
2. **aws-c2-mgmt-account-factory** (creates connectivity account)
3. **aws-c2-mgmt-identity-center** (creates sso permissions)
4. **aws-c2-log-archive**          (creates audit log archive)
5. **aws-c2-security**             (creates security tooling)
6. **aws-c2-connectivity**         ← *You are here*

### Implementation Guide

For detailed deployment instructions, refer to the [NTC Quickstart Guide](https://docs.nuvibit.com/getting-started/quickstart/).

## 🔗 Additional Resources

- **[NTC Documentation](https://docs.nuvibit.com/)** - Complete documentation for all NTC building blocks
- **[NTC Library](https://docs.nuvibit.com/ntc-library/)** - Browse all available NTC modules
- **[Nuvibit AWS Reference Architecture](https://docs.nuvibit.com/whitepapers/nuvibit-aws-reference-architecture/)** - Architecture whitepaper
- **[CI/CD Pipelines for IaC](https://docs.nuvibit.com/whitepapers/cicd-pipelines-iac-delivery/)** - CI/CD best practices
- **[Nuvibit Website](https://nuvibit.com/)** - Company information and contact

## 💡 Use Cases

These implementation blueprints serve multiple purposes:

- **Reference Architecture**: Learn how to structure enterprise AWS environments
- **Starter Template**: Copy and customize for your own AWS organization
- **Best Practices**: Study production-ready configurations and patterns
- **Training Material**: Understand NTC building blocks in real-world context
- **Proof of Concept**: Evaluate NTC capabilities before full adoption

## 🤝 Support

For questions, issues, or consultation regarding NTC implementation:

- **Documentation**: [docs.nuvibit.com](https://docs.nuvibit.com/)
- **Contact**: [nuvibit.com/contact](https://nuvibit.com/contact/)
- **Email**: info@nuvibit.com

## 📄 License

This repository demonstrates the usage of the Nuvibit Terraform Collection. Please refer to your NTC subscription agreement for licensing terms.

---

**Built with ❤️ by [Nuvibit](https://nuvibit.com/)**
