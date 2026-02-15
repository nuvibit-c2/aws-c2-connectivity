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
      # grant access to ntc-account-factory baseline pipelines
      type        = "AWS"
      identifiers = local.ntc_parameters["mgmt-account-factory"]["baseline_role_arns"]
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
      module.ntc_core_network.transit_gateway_arns_by_name["tgw-core-zurich"],
      module.ntc_core_network.transit_gateway_arns_by_name["tgw-core-frankfurt"]
    ]
  }
  # permissions required to manage subdomain delegations
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
      "route53:GetHostedZone",
    ]
    resources = [module.ntc_route53_nuvibit_dev.zone_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ntc_baseline" {
  name   = "ntc-baseline-permissions"
  role   = aws_iam_role.ntc_baseline.id
  policy = data.aws_iam_policy_document.ntc_baseline_permissions.json
}