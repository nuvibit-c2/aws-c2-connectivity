# for hybrid dns route53 resolver endpoints are required
# https://docs.aws.amazon.com/whitepapers/latest/hybrid-cloud-dns-options-for-vpc/route-53-resolver-endpoints-and-forwarding-rules.html

locals {
  # NOTE: resolver endpoints are not enabled in this example to avoid unnecessary cost in our integration environment
  enable_resolver_endpoints = false
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_resolver" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/resolver?ref=2.1.0"

  region = "eu-central-1"

  # inbound resolver endpoints are required for conditional dns forwarding from on-premise dns servers to aws
  resolver_endpoint_inbound = {
    create_endpoint = local.enable_resolver_endpoints
    resolver_name   = "route53-inbound-resolver-endpoint"
    # (optional) you can attach existing security groups instead of creating a new one
    security_group_ids = []
    subnets = [for index, id in module.ntc_vpc_central_endpoints.subnet_ids["hybrid-private"] :
      {
        subnet_id = id
        # (optional but recommended) set a static ip for the resolver endpoint
        static_ip = cidrhost(module.ntc_vpc_central_endpoints.subnet_cidr_blocks["hybrid-private"][index], 4)
      }
    ]
  }

  # outbound resolver endpoints are required for dns forwarding rules from aws to on-premise dns servers
  resolver_endpoint_outbound = {
    create_endpoint = local.enable_resolver_endpoints
    resolver_name   = "route53-outbound-resolver-endpoint"
    # (optional) you can attach existing security groups instead of creating a new one
    security_group_ids = []
    subnets = [for index, id in module.ntc_vpc_central_endpoints.subnet_ids["hybrid-private"] :
      {
        subnet_id = id
        # (optional but recommended) set a static ip for the resolver endpoint
        static_ip = cidrhost(module.ntc_vpc_central_endpoints.subnet_cidr_blocks["hybrid-private"][index], 5)
      }
    ]
  }

  # only allow dns traffic for resolver endpoints (by default tcp/udp 53)
  resolver_endpoint_security_group = {
    create_security_group = local.enable_resolver_endpoints
    name                  = "route53-resolver-endpoint-sg"
    description           = "DNS traffic inbound and outbound resolvers"
    vpc_id                = module.ntc_vpc_central_endpoints.vpc_id

    ingress_rules = [
      {
        protocol = "tcp"
        # add cidrs or prefix list of on-premises dns servers (if omitted default is 0.0.0.0/0)
        cidr_blocks = [
          # "192.168.8.8/32",
          # "192.168.9.9/32"
        ]
        prefix_list_ids = [
          module.ntc_core_network.prefix_list_ids_by_region_and_name["eu-central-1/cidrs-onprem-dns"].id
        ]
        # (optional) allow outbound resolver to forward to inbound resolver
        self = true
      },
      {
        protocol = "udp"
        # add cidrs or prefix list of on-premises dns servers (if omitted default is 0.0.0.0/0)
        cidr_blocks = []
        prefix_list_ids = [
          module.ntc_core_network.prefix_list_ids_by_region_and_name["eu-central-1/cidrs-onprem-dns"].id
        ]
        # (optional) allow outbound resolver to forward to inbound resolver
        self = true
      }
    ]

    egress_rules = [
      {
        protocol = "tcp"
        # add cidrs or prefix list of on-premises dns servers (if omitted default is 0.0.0.0/0)
        cidr_blocks = []
        prefix_list_ids = [
          module.ntc_core_network.prefix_list_ids_by_region_and_name["eu-central-1/cidrs-onprem-dns"].id
        ]
        # (optional) allow outbound resolver to forward to inbound resolver
        self = true
      },
      {
        protocol = "udp"
        # add cidrs or prefix list of on-premises dns servers (if omitted default is 0.0.0.0/0)
        cidr_blocks = []
        prefix_list_ids = [
          module.ntc_core_network.prefix_list_ids_by_region_and_name["eu-central-1/cidrs-onprem-dns"].id
        ]
        # (optional) allow outbound resolver to forward to inbound resolver
        self = true
      }
    ]
  }

  resolver_rules = [for rule in [
    {
      domain_name = "domain.onprem"
      rule_name   = "forward onprem dns domain"
      rule_type   = "FORWARD"
      vpc_associations = {
        "central-endpoints" = module.ntc_vpc_central_endpoints.vpc_id
      }
      target_ips = [
        # add ips of on-premises dns servers (default port is 53)
        "192.168.8.8",
        "192.168.9.9"
      ]
      # (optional) share resolver rule with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "945766593056"]
      # ram_share_allow_external_principals = false
    },
    {
      domain_name = "domain.cloud"
      rule_name   = "do not forward cloud domain"
      rule_type   = "SYSTEM"
      vpc_associations = {
        "central-endpoints" = module.ntc_vpc_central_endpoints.vpc_id
      }
      # (optional) share resolver rule with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "945766593056"]
      # ram_share_allow_external_principals = false
    }
  ] : rule if local.enable_resolver_endpoints]

  # resolver query logs capture dns queries originating in associated vpcs and can be delivered to s3, cloudwatch and kinesis-data-firehose.
  # query logging does not require resolver endpoints or rules
  # a vpc can be associated with multiple configurations to send query logs to multiple targets in parallel e.g. s3 + cloudwatch
  resolver_query_log_configs = [
    {
      # central s3 bucket in log archive for audit and compliance (long-term retention)
      name             = "dns-query-logs-archive"
      destination_type = "s3"
      destination_arn  = local.ntc_parameters["log-archive"]["log_bucket_arns"]["dns_query_logs"]
      vpc_associations = {
        "central-endpoints" = module.ntc_vpc_central_endpoints.vpc_id
        "prod-stage"        = module.ntc_vpc_prod_stage.vpc_id
      }
      # (optional) share query logging configuration with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # accounts can associate their own vpcs and logs are delivered to the destination of this configuration
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads/prod"]
      ]
      ram_share_allow_external_principals = false
    },
    {
      # cloudwatch for troubleshooting and short-term analysis (e.g. logs insights)
      name             = "dns-query-logs-troubleshooting"
      destination_type = "cloud-watch-logs"
      # cloudwatch log group, kms key and log group resource policy will be created if 'destination_arn' is omitted
      destination_arn = ""
      vpc_associations = {
        "central-endpoints" = module.ntc_vpc_central_endpoints.vpc_id
      }
      cloudwatch_options = {
        name_prefix       = "/aws/route53resolver/"
        retention_in_days = 30
        # (optional) use an existing kms key instead of creating a new one
        use_existing_kms_key = false
        kms_key_arn          = ""
      }
    },
    # {
    #   name             = "dns-query-logs-firehose"
    #   destination_type = "kinesis-data-firehose"
    #   destination_arn  = "KINESIS_DATA_FIREHOSE_ARN"
    # }
  ]
}
