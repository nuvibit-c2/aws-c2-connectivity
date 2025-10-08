# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53 - PUBLIC HOSTED ZONE
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_nuvibit_dev" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53?ref=1.3.0"

  zone_force_destroy = false

  # name of the route53 hosted zone
  zone_name        = "nuvibit.dev"
  zone_description = "Managed by Terraform"

  # private hosted zones require at least one vpc to be associated
  # public hosted zones cannot have any vpc associated
  zone_type = "public"

  # list of dns records which should be created in hosted zone. alias records are a special type of records
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html
  dns_records = [
    {
      name = ""
      type = "TXT"
      ttl  = 300
      values = [
        "https://xkcd.com/1361/"
      ]
    }
  ]

  # (optional) List of subdomains with corresponding nameservers which should be delegated
  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-routing-traffic-for-subdomains.html
  zone_delegation_list = [
    {
      # SaaS PoC 'aws-c2-ares-dev'
      subdomain_zone_name = "portal"
      subdomain_nameserver_list = [
        "ns-679.awsdns-20.net.",
        "ns-1565.awsdns-03.co.uk.",
        "ns-155.awsdns-19.com.",
        "ns-1286.awsdns-32.org.",
      ]
      dnssec_enabled   = true
      dnssec_ds_record = "46737 13 2 D053F385C76334C66706D9B4A169375E73EB5E9D1C7450AF3B4ECF3573CC6C4F"
    },
    {
      # NTC Summit Demo 'aws-c3'
      subdomain_zone_name = "summit"
      subdomain_nameserver_list = [
        "ns-460.awsdns-57.com.",
        "ns-676.awsdns-20.net.",
        "ns-1608.awsdns-09.co.uk.",
        "ns-1027.awsdns-00.org.",
      ]
      dnssec_enabled = true
      dnssec_ds_record = "13790 13 2 4ADEA6D37A6064708DCAE2BF1298A30A54EEAE4B43A22354446236353C916343"
    },
    {
      # c1 zone delegation at 'aws-c1' ( https://github.com/nuvibit-c1/aws-c1-connectivity/blob/main/ntc_route53.tf )
      subdomain_zone_name = "c1"
      subdomain_nameserver_list = [
        "ns-1134.awsdns-13.org",
        "ns-1873.awsdns-42.co.uk",
        "ns-712.awsdns-25.net",
        "ns-72.awsdns-09.com",
      ]
      dnssec_enabled = true
      dnssec_ds_record = "48427 13 2 01A4F6DF790335CDBFCBB6C6E8160E45BF50A707B5D061D2F66928EC1CCB5FEC"
    },
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
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/dnssec?ref=1.3.0"

  zone_id = module.ntc_route53_nuvibit_dev.zone_id

  # dnssec key can be rotated by creating a new 'inactive' key-signing-key and adding new DS records in root domain
  # WARNING: old key should stay active until new key-signing-key is provisioned and new DS records are propagated
  key_signing_keys = [
    {
      ksk_name   = "ksk-1"
      ksk_status = "active"
    },
    {
      ksk_name   = "ksk-2"
      ksk_status = "inactive"
    }
  ]

  providers = {
    # dnssec requires the kms key to be in us-east-1
    aws.us_east_1 = aws.use1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53 - QUERY LOGGING
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_nuvibit_dev_query_logging" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/query-logs?ref=1.3.0"

  # query logging requires a public hosted zone
  zone_id = module.ntc_route53_nuvibit_dev.zone_id

  # cloudwatch_name_prefix          = "/aws/route53/"
  # cloudwatch_resource_policy_name = "route53-query-logs"
  # cloudwatch_retention_in_days    = null
  # cloudwatch_kms_key_use_existing = false
  # cloudwatch_kms_key_arn          = ""

  providers = {
    # cloudwatch log group must be in us-east-1
    aws.us_east_1 = aws.use1
  }
}
