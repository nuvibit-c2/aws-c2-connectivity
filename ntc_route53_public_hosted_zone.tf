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
    # {
    #   subdomain_zone_name = "int"
    #   subdomain_nameserver_list = [
    #     "ns-999.awsdns-00.co.uk.",
    #     "ns-888.awsdns-00.org.",
    #     "ns-777.awsdns-00.com.",
    #     "ns-666.awsdns-00.net.",
    #   ]
    #   dnssec_enabled   = true
    #   dnssec_ds_record = "26175 13 2 44444A317DAEC3A213AB156BE09A22E333DDD10903B666B3A2301ECFB3C59933"
    # }
    {
      # spacelift self-hosted PoC in 'aws-c2-shared-services'
      subdomain_zone_name = "spacelift"
      subdomain_nameserver_list = [
        "ns-1785.awsdns-31.co.uk.",
        "ns-962.awsdns-56.net.",
        "ns-462.awsdns-57.com.",
        "ns-1424.awsdns-50.org.",
      ]
      dnssec_enabled   = true
      dnssec_ds_record = "21182 13 2 2ED1D1F4654A4CF097EE83B718BCD76D2385F6348466A131F12F563C2EBAE494"
    },
    # DEMO ACCOUNTS
    {
      subdomain_zone_name = "apollo-dev"
      subdomain_nameserver_list = [
        "ns-1213.awsdns-23.org.",
        "ns-2023.awsdns-60.co.uk.",
        "ns-280.awsdns-35.com.",
        "ns-575.awsdns-07.net.",
      ]
      dnssec_enabled   = false
    },
    {
      subdomain_zone_name = "apollo-prod"
      subdomain_nameserver_list = [
        "ns-388.awsdns-48.com.",
        "ns-1307.awsdns-35.org.",
        "ns-601.awsdns-11.net.",
        "ns-1741.awsdns-25.co.uk.",
      ]
      dnssec_enabled   = false
    }
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
