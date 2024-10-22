# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "euc1"
  region = "eu-central-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "euc2"
  region = "eu-central-2"
  default_tags {
    tags = local.default_tags
  }
}

# provider for us-east-1 region is sometimes required for specific features or services
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
  default_tags {
    tags = local.default_tags
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.33"
      configuration_aliases = []
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_region" "default" {}
data "aws_caller_identity" "current" {}
# data "aws_availability_zones" "available" {
#   state = "available"
# }

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  default_tags = {
    ManagedBy     = "OpenTofu"
    ProvisionedBy = "aws-c2-connectivity"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM ROLE - ASSUMABLE BY ACCOUNT BASELINE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "ntc_baseline" {
  name               = "ntc-baseline-role"
  assume_role_policy = data.aws_iam_policy_document.ntc_baseline_trust.json
}

data "aws_iam_policy_document" "ntc_baseline_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = try(local.ntc_parameters["mgmt-account-factory"]["baseline_role_arns"], ["944538260333"])
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ntc_baseline_permissions" {
  # permission required to manage transit gateway attachments
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DescribeTransitGatewayAttachments",
      "ec2:AssociateTransitGatewayRouteTable",
      "ec2:EnableTransitGatewayRouteTablePropagation",
      "ec2:GetTransitGatewayAttachmentPropagations",
    ]
    resources = [
      module.ntc_core_network_frankfurt.transit_gateway_arn,
      module.ntc_core_network_zurich.transit_gateway_arn
    ]
  }
  # permissions required to manage subdomain delegations
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:GetHostedZone",
    ]
    resources = [module.ntc_route53_nuvibit_dev.zone_id]
  }
}

resource "aws_iam_role_policy" "ntc_baseline" {
  name   = "ntc-baseline-permissions"
  role   = aws_iam_role.ntc_baseline.id
  policy = data.aws_iam_policy_document.ntc_baseline_permissions.json
}