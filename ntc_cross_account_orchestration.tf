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

  providers = {
    aws = aws.euc1
  }
}
