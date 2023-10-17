# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # name of the route53 hosted zone
  route53_zone_name          = "mydomain.internal"
  route53_zone_description   = "Managed by Terraform"
  # 
  route53_zone_force_destroy = false
  # private hosted zones require at least one vpc to be associated
  # public hosted zones cannot have any vpc associated
  route53_zone_type          = "private"
  route53_zone_associated_vpc_ids = [
    module.ntc_vpc_prod_stage.vpc_id
  ]

  # list of dns records which should be created in hosted zone. alias records are a special type of records
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html
  route53_dns_records = [
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
      name = "logs-endpoint"
      type = "CNAME"
      ttl  = 300
      alias = {
        enable_alias = true
        target_domain_name     = module.ntc_vpc_prod_stage.interface_endpoints[0].
        target_hosted_zone_id  = module.ntc_vpc_prod_stage.interface_endpoints[0].
        evaluate_target_health = true
        
      }
    }
  ]

  # (optional) 
  route53_zone_delegation_list = []
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_mydomain_internal" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53?ref=beta"

  zone_name               = local.route53_zone_name
  zone_type               = local.route53_zone_type
  zone_associated_vpc_ids = local.route53_zone_associated_vpc_ids
  zone_force_destroy      = local.route53_zone_force_destroy
  zone_description        = local.route53_zone_description
  zone_delegation_list    = local.route53_zone_delegation_list
  dns_records             = local.route53_dns_records

  providers = {
    aws = aws.euc1
  }
}
