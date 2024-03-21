# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53 - PUBLIC HOSTED ZONE
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_nuvibit_dev" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53?ref=feat-dnssec"

  # name of the route53 hosted zone
  zone_name        = "nuvibit.dev"
  zone_description = "Managed by Terraform"
  # 
  zone_force_destroy = false
  # private hosted zones require at least one vpc to be associated
  # public hosted zones cannot have any vpc associated
  zone_type = "public"

  # list of dns records which should be created in hosted zone. alias records are a special type of records
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html
  dns_records = [
    {
      name = ""
      type = "CNAME"
      ttl  = 300
      values = [
        "nuvibit.com"
      ]
    }
  ]

  # (optional) List of subdomains with corresponding nameservers which should be delegated
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-routing-traffic-for-subdomains.html
  zone_delegation_list = [
    # {
    #   subdomain_zone_name       = "int"
    #   subdomain_nameserver_list = [
    #     "ns-999.awsdns-00.co.uk.",
    #     "ns-888.awsdns-00.org.",
    #     "ns-777.awsdns-00.com."
    #     "ns-666.awsdns-00.net.",
    #   ]
    # }
  ]

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53 - DNSSEC
# ---------------------------------------------------------------------------------------------------------------------
# WARNING: disabling DNSSEC before DS records expire can lead to domain becoming unavailable on the internet
# https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-disable.html
module "ntc_route53_nuvibit_dev_dnssec" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/dnssec?ref=feat-dnssec"

  zone_id              = module.ntc_route53_nuvibit_dev.zone_id
  key_signing_keys = [
    {
      ksk_name   = "ksk-1"
      ksk_status = "inactive"
    },
    # dnssec key can be rotated by creating a new 'inactive' key-signing-key and adding new DS records in root domain
    # WARNING: old key should stay active until new key-signing-key is provisioned and new DS records are propagated
    {
      ksk_name   = "ksk-2"
      ksk_status = "active"
    }
  ]

  providers = {
    # dnssec requires the kms key to be in us-east-1
    aws.us_east_1 = aws.use1
  }
}
