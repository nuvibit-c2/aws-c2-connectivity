# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53 - PUBLIC HOSTED ZONE
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_nuvibit_dev" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53?ref=2.0.0"

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
      # c1 zone delegation at 'aws-c1' ( https://github.com/nuvibit-c1/aws-c1-connectivity/blob/main/ntc_route53.tf )
      subdomain_zone_name = "c1"
      subdomain_nameserver_list = [
        "ns-1134.awsdns-13.org",
        "ns-1873.awsdns-42.co.uk",
        "ns-712.awsdns-25.net",
        "ns-72.awsdns-09.com",
      ]
      dnssec_enabled   = true
      dnssec_ds_record = "48427 13 2 01A4F6DF790335CDBFCBB6C6E8160E45BF50A707B5D061D2F66928EC1CCB5FEC"
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
      dnssec_enabled   = true
      dnssec_ds_record = "13790 13 2 4ADEA6D37A6064708DCAE2BF1298A30A54EEAE4B43A22354446236353C916343"
    },
  ]

  dnssec_config = {
    enabled = true
    key_signing_keys = [
      {
        ksk_name   = "ksk-1"
        ksk_status = "active"
      },
      # {
      #   ksk_name   = "ksk-2"
      #   ksk_status = "inactive"
      # }
    ]
  }

  query_logs_config = {
    enabled                = true
    cloudwatch_name_prefix = "/aws/route53/nuvibit-dev"
  }
}
