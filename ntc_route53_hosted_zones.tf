# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53 - PRIVATE HOSTED ZONE
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_mydomain_internal" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53?ref=1.0.3"

  # name of the route53 hosted zone
  zone_name        = "mydomain.internal"
  zone_description = "Managed by Terraform"
  # 
  zone_force_destroy = false
  # private hosted zones require at least one vpc to be associated
  # public hosted zones cannot have any vpc associated
  zone_type = "private"
  zone_vpc_associations = [
    {
      vpc_id = module.ntc_vpc_prod_stage.vpc_id
      # (optional) by default the provider region will be used
      vpc_region = null
    }
  ]

  # (optional) set to true if you need to create the vpc associations in another account
  # WARNING: the hosted zone will be recreated and the intial vpc associations cannot be updated anymore
  # this is a workaround required becuase of an aws api limitation
  zone_vpc_association_exception = false

  # list of dns records which should be created in hosted zone. alias records are a special type of records
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html
  dns_records = [
    {
      name = ""
      type = "A"
      ttl  = 300
      values = [
        "192.168.1.1",
        "192.168.2.2"
      ]
    },
    {
      name = "nuvibit"
      type = "CNAME"
      ttl  = 300
      values = [
        "nuvibit.com"
      ]
    },
    {
      name = "cloudwatch-endpoint"
      type = "A"
      ttl  = 300
      alias = {
        enable_alias           = true
        target_dns_name        = module.ntc_vpc_central_endpoints.interface_endpoints.logs.dns_names[0]
        target_hosted_zone_id  = module.ntc_vpc_central_endpoints.interface_endpoints.logs.hosted_zone_id
        evaluate_target_health = true
      }
    }
  ]

  # (optional) 
  zone_delegation_list = []

  providers = {
    aws = aws.euc1
  }
}
