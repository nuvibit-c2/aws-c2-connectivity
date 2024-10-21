# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CROSS ACCOUNT ORCHESTRATION
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_cross_account_orchestration" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-cross-account-orchestration?ref=alpha"

  # 'ntc-parameters' bucket is required containing account context information required to evaluate 'orchestration_rules'
  # 'account-map' from 'ntc-account-factory' must be stored in 'ntc-parameters'
  ntc_parameters_bucket_name = local.ntc_parameters_bucket_name

  # organization id to limit bucket access to organization accounts
  org_id = local.ntc_parameters["mgmt-organizations"]["org_id"]

  # this bucket stores information for cross account orchestration which will be provided by member accounts
  orchestration_bucket_name = "ntc-cross-account-orchestration-connectivity"

  # notify on orchestration step function errors
  orchestration_notification_settings = {
    # identify for which AWS Organization notifications are sent
    org_identifier = "c2"
    # multiple subscriptions with different protocols is supported
    subscriptions = [
      {
        protocol  = "email"
        endpoints = ["stefano.franco@nuvibit.com"]
      }
    ]
  }

  # (optional) configure settings for the orchestration pipeline
  orchestration_pipeline_settings = {
    terraform_parallelism = 10
    terraform_binary      = "opentofu"
    terraform_version     = "1.8.3"
    aws_provider_version  = "5.72.0"
    provider_default_tags = { ManagedBy = "ntc-cross-account-orchestration" }
    pipeline_compute_type = "BUILD_GENERAL1_SMALL"
    pipeline_logs_enabled = true
    # before you can delete the orchestration pipeline you need to decommission it
    # WARNING: this will destroy all resources managed by the orchestration pipeline 
    decommission = false
  }

  # trigger orchestration when a organization member account creates a JSON file in the orchestration_bucket and a rule matches
  orchestration_rules = [
    {
      rule_name          = "r53_subdomain_delegation_workloads"
      orchestration_type = "route53_subdomain_delegation"
      # orchestrate cross-account route53 public subdomain delegation
      route53_delegation_settings = {
        root_zone_id             = module.ntc_route53_nuvibit_dev.zone_id
        ns_record_ttl_in_seconds = 3600 # 1h = 3600; 1d = 86400
        ds_record_ttl_in_seconds = 3600 # 1h = 3600; 1d = 86400
        dnssec_enabled           = true
        # (optional) subdomain zone name must match value specified in account tag
        subdomain_equals_account_tag = "AccountDNSZoneName"
        # (optional) separator when multiple zones are specified in account tag
        subdomain_separator_account_tag = " " # e.g. "app1.example.com app2.example.com"
      }
      # by default orchestration_rules will apply to all accounts
      condition = {}
    },
    {
      rule_name          = "tgw_attachment_workloads_prod_euc1"
      orchestration_type = "transit_gateway_vpc_attachment"
      # orchestrate cross-account transit gateway vpc attachments associations and propagations
      transit_gateway_vpc_attachment_settings = {
        region                        = "eu-central-1"
        transit_gateway_id            = module.ntc_core_network_frankfurt.transit_gateway_id
        associate_with_route_table_id = module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-prod"]
        propagate_to_route_table_ids = [
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-hub"],
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-prod"],
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-onprem"]
        ]
      }
      # by default orchestration_rules will apply to all accounts
      # a condition can additionaly restrict to which accounts orchestration_rules will apply
      condition = {
        test     = "StringEquals" # StringEquals, StringLike
        variable = "ouPath"       # accountId, accountName, ouPath, accountTag:KEY_NAME
        values   = ["/root/workloads/prod"]
      }
    },
    {
      rule_name          = "tgw_attachment_workloads_dev_euc1"
      orchestration_type = "transit_gateway_vpc_attachment"
      s3_file_prefix     = "tgw_attachment/"
      # orchestrate cross-account transit gateway vpc attachments associations and propagations
      transit_gateway_vpc_attachment_settings = {
        region                        = "eu-central-1"
        transit_gateway_id            = module.ntc_core_network_frankfurt.transit_gateway_id
        associate_with_route_table_id = module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-dev"]
        propagate_to_route_table_ids = [
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-hub"],
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-dev"],
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-onprem"]
        ]
      }
      # by default orchestration_rules will apply to all accounts
      # a condition can additionaly restrict to which accounts orchestration_rules will apply
      condition = {
        test     = "StringEquals" # StringEquals, StringLike
        variable = "ouPath"       # accountId, accountName, ouPath, accountTag:KEY_NAME
        values   = ["/root/workloads/dev"]
      }
    }
  ]

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CROSS ACCOUNT ORCHESTRATION - TRIGGER
# ---------------------------------------------------------------------------------------------------------------------
# this is an example how an organization member account would trigger a cross-account orchestration
# normally this would be defined in a different account which would then trigger the orchestration in this account
module "ntc_cross_account_orchestration_trigger" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-cross-account-orchestration//modules/orchestration-trigger?ref=alpha"

  orchestration_triggers = [
    {
      trigger_name       = "r53_delegation"
      s3_bucket_name     = "ntc-cross-account-orchestration-connectivity"
      orchestration_type = "route53_subdomain_delegation"
      route53_delegation_info = {
        zone_id     = "Z028999726P9BKFOXIYXX"
        zone_name   = "orchestration.nuvibit.dev"
        nameservers = [
          "ns-1111.awsdns-12.org",
          "ns-8888.awsdns-39.co.uk",
          "ns-444.awsdns-59.com",
          "ns-888.awsdns-36.net",
        ]
        # (optional) DS record is required when DNSSEC is enabled
        ds_record = "22282 13 2 9E1XXEBE0FABCEB20ED2A401CXXX0DA4C3A474322DF2C414XX7FCCFF83F1BBXX"
      }
    },
    {
      trigger_name       = "tgw_attachment_euc1"
      s3_bucket_name     = "ntc-cross-account-orchestration-connectivity"
      orchestration_type = "transit_gateway_vpc_attachment"
      transit_gateway_vpc_attachment_info = {
        region                        = "eu-central-1"
        vpc_id                        = "vpc-03162c1dfd6d7c6xx"
        vpc_name                      = "orchestration-vpc"
        transit_gateway_attachment_id = "tgw-attach-055962245c0a83800"
      }
    }
  ]
}