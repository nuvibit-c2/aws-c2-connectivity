# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CROSS ACCOUNT ORCHESTRATION
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_cross_account_orchestration" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-cross-account-orchestration?ref=beta"

  # organization id to limit bucket access to organization accounts
  org_id = local.ntc_parameters["mgmt-organizations"]["org_id"]

  # to get organizational information about accounts an assumable iam role is required in the org management account
  organization_reader_role_name = "ntc-org-account-reader"

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

  # trigger orchestration when a organization member account creates a JSON file in the orchestration_bucket and a rule matches
  orchestration_rules = [
    {
      rule_name          = "r53_subdomain_delegation_workloads"
      orchestration_type = "route53_subdomain_delegation"
      s3_file_prefix     = "r53_delegation/"
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
      # by default orchestration_rules will apply to all accounts where 's3_file_prefix' matches
      condition = {}
    },
    {
      rule_name          = "tgw_attachment_workloads_prod"
      orchestration_type = "transit_gateway_vpc_attachment"
      s3_file_prefix     = "tgw_attachment/"
      # orchestrate cross-account transit gateway vpc attachments associations and propagations
      transit_gateway_vpc_attachment_settings = {
        transit_gateway_id            = module.ntc_core_network_frankfurt.transit_gateway_id
        associate_with_route_table_id = module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-prod"]
        propagate_to_route_table_ids = [
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-hub"],
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-prod"],
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-onprem"]
        ]
      }
      # by default orchestration_rules will apply to all accounts where 's3_file_prefix' matches
      # a condition can additionaly restrict to which accounts orchestration_rules will apply
      condition = {
        test     = "StringEquals" # StringEquals, StringLike
        variable = "ouPath"       # accountId, accountName, ouPath, accountTag:KEY_NAME
        values   = ["/root/workloads/prod"]
      }
    },
    {
      rule_name          = "tgw_attachment_workloads_dev"
      orchestration_type = "transit_gateway_vpc_attachment"
      s3_file_prefix     = "tgw_attachment/"
      # orchestrate cross-account transit gateway vpc attachments associations and propagations
      transit_gateway_vpc_attachment_settings = {
        transit_gateway_id            = module.ntc_core_network_frankfurt.transit_gateway_id
        associate_with_route_table_id = module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-dev"]
        propagate_to_route_table_ids = [
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-hub"],
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-dev"],
          module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-onprem"]
        ]
      }
      # by default orchestration_rules will apply to all accounts where 's3_file_prefix' matches
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
# normally this would be defined in another account which would then trigger the orchestration in this account
module "ntc_cross_account_orchestration_trigger" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-cross-account-orchestration//modules/orchestration-trigger?ref=beta"

  orchestration_triggers = [
    # {
    #   trigger_name = "app1_nuvibit_dev"
    #   s3_bucket_name = "ntc-cross-account-orchestration-connectivity"
    #   # file prefix must match with central orchestration configuration
    #   s3_file_prefix     = "r53_delegation/"
    #   orchestration_type = "route53_subdomain_delegation"
    #   route53_delegation_info = {
    #     zone_id     = ""
    #     zone_name   = ""
    #     nameservers = ""
    #     # (optional) DS record is required when DNSSEC is enabled
    #     ds_record = ""
    #   }
    # },
    # {
    #   trigger_name = "vpc_app1_euc1"
    #   s3_bucket_name = "ntc-cross-account-orchestration-connectivity"
    #   # file prefix must match with central orchestration configuration
    #   s3_file_prefix     = "tgw_attachment/"
    #   orchestration_type = "transit_gateway_vpc_attachment"
    #   transit_gateway_vpc_attachment_info = {
    #     vpc_id            = ""
    #     vpc_name          = ""
    #     tgw_attachment_id = ""
    #   }
    # }
  ]
}