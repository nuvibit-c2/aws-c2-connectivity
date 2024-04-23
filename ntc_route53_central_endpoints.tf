# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # for centralized vpc interface endpoints a dedicated private hosted zone is required for each endpoint (ec2 -> ec2.eu-central-2.amazonaws.com)
  # these private hosted zones need to be associated to all vpcs which should access the centralized endpoints
  # https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/centralized-access-to-vpc-private-endpoints.html

  route53_central_endpoints = {
    for endpoint in module.ntc_vpc_central_endpoints.interface_endpoints : endpoint.common_name => {
      # name of the route53 hosted zone
      zone_name        = endpoint.private_hosted_zone_name
      zone_description = "Managed by Terraform"
      # 
      zone_force_destroy = true
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
          alias = {
            enable_alias           = true
            target_dns_name        = endpoint.dns_names[0]
            target_hosted_zone_id  = endpoint.hosted_zone_id
            evaluate_target_health = true
          }
        },
        {
          name = "*"
          type = "A"
          ttl  = 300
          alias = {
            enable_alias           = true
            target_dns_name        = endpoint.dns_names[0]
            target_hosted_zone_id  = endpoint.hosted_zone_id
            evaluate_target_health = true
          }
        }
      ]
    }
    # private dns must be disabled for centralized vpc endpoints
    if endpoint.private_dns_enabled == false
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_central_endpoints" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53?ref=1.1.2"

  for_each = local.route53_central_endpoints

  zone_name                      = each.value.zone_name
  zone_description               = each.value.zone_description
  zone_type                      = each.value.zone_type
  zone_force_destroy             = each.value.zone_force_destroy
  dns_records                    = each.value.dns_records
  zone_vpc_associations          = each.value.zone_vpc_associations
  zone_vpc_association_exception = each.value.zone_vpc_association_exception

  providers = {
    aws = aws.euc1
  }
}
