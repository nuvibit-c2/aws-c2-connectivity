# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  route53_mydomain_internal = {
    # name of the route53 hosted zone
    zone_name        = "mydomain.internal"
    zone_description = "Managed by Terraform"
    # 
    zone_force_destroy = false
    # private hosted zones require at least one vpc to be associated
    # public hosted zones cannot have any vpc associated
    zone_type = "private"
    zone_associated_vpc_ids = [
      module.ntc_vpc_prod_stage.vpc_id
    ]

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
          target_dns_name        = module.ntc_vpc_prod_stage.interface_endpoints.logs.dns_names[0]
          target_hosted_zone_id  = module.ntc_vpc_prod_stage.interface_endpoints.logs.hosted_zone_id
          evaluate_target_health = true
        }
      }
    ]

    # (optional) 
    zone_delegation_list = []
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_mydomain_internal" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53?ref=beta"

  zone_name               = local.route53_mydomain_internal.zone_name
  zone_description        = local.route53_mydomain_internal.zone_description
  zone_type               = local.route53_mydomain_internal.zone_type
  zone_associated_vpc_ids = local.route53_mydomain_internal.zone_associated_vpc_ids
  zone_force_destroy      = local.route53_mydomain_internal.zone_force_destroy
  zone_delegation_list    = local.route53_mydomain_internal.zone_delegation_list
  dns_records             = local.route53_mydomain_internal.dns_records

  providers = {
    aws = aws.euc1
  }
}
