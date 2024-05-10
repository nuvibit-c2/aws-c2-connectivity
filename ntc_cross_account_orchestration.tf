# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CROSS ACCOUNT ORCHESTRATION
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_cross_account_orchestration" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-cross-account-orchestration?ref=beta"

  # this bucket stores information for cross account orchestration which will be provided by member accounts
  orchestration_bucket_name = "ntc-cross-account-orchestration-connectivity"

  # organization id to limit bucket access to organization accounts
  org_id = local.ntc_parameters["mgmt-organizations"]["org_id"]

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

  # orchestration_step_function_settings = {
  #   # this function will create subdomain delegation records in a central hosted zone
  #   route53_subdomain_delegation = {
  #     enabled        = true
  #     s3_file_prefix = "r53_delegation"
  #     root_zone_id   = ""
  #     root_zone_name = ""
  #   }
  #   # this function will add route table asssociations and propagations to vpc attachment in a central transit gateway
  #   transit_gateway_vpc_attachment = {
  #     enabled                           = true
  #     s3_file_prefix                    = "tgw_attachment"
  #     transit_gateway_id                = ""
  #     transit_gateway_association_rules = []
  #     transit_gateway_propagation_rules = []
  #   }
  #   # TODO: should orchestration also get organizational data like security tooling? caching dynamodb would be required
  # }

  providers = {
    aws = aws.euc1
  }
}
