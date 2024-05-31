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
        root_zone_id   = module.ntc_route53_nuvibit_dev.zone_id
        dnssec_enabled = true
        # (optional) limit subdomain zone name to value specified in account tag
        subdomain_equals_account_tag = "AccountDNSZoneName"
      }
      # by default this rule will apply to all accounts where 's3_file_prefix' matches
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
      # condition to limit to which accounts this rule applies where 's3_file_prefix' also matches
      condition = {
        test     = "StringEquals" # StringEquals, StringLike
        variable = "ou_path"      # account_id, account_name, ou_path, account_tag/KEY_NAME
        values   = ["/root/workloads/prod"]
      }
    }
  ]

  providers = {
    aws = aws.euc1
  }
}
