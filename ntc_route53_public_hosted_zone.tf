# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53 - PUBLIC HOSTED ZONE
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_c2_nuvibit_dev" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53?ref=2.0.1"

  zone_force_destroy = false

  # name of the route53 hosted zone
  zone_name        = "c2.nuvibit.dev"
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
    #   subdomain_zone_name = "example"
    #   subdomain_nameserver_list = [
    #     "ns-111.awsdns-11.com.",
    #     "ns-2222.awsdns-22.org.",
    #     "ns-333.awsdns-33.net.",
    #     "ns-4444.awsdns-44.co.uk.",
    #   ]
    #   dnssec_enabled   = false
    #   dnssec_ds_record = ""
    # },
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
    cloudwatch_name_prefix = "/aws/route53/nuvibit-c2"
  }
}
