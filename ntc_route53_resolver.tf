# for hybrid dns route53 resolver endpoints are required
# https://docs.aws.amazon.com/whitepapers/latest/hybrid-cloud-dns-options-for-vpc/route-53-resolver-endpoints-and-forwarding-rules.html

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_resolver" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/resolver?ref=1.0.2"
  count  = 0 # disabled for demo purposes

  # inbound resolver endpoints are required for conditional dns forwarding from on-premise dns servers to aws
  resolver_endpoint_inbound = {
    create_endpoint = true
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
    create_endpoint = true
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
    create_security_group = true
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
          module.ntc_vpc_central_endpoints.customer_managed_prefix_lists["onprem-dns-servers"].id
        ]
        # (optional) allow outbound resolver to forward to inbound resolver
        self = true
      },
      {
        protocol = "udp"
        # add cidrs or prefix list of on-premises dns servers (if omitted default is 0.0.0.0/0)
        cidr_blocks = []
        prefix_list_ids = [
          module.ntc_vpc_central_endpoints.customer_managed_prefix_lists["onprem-dns-servers"].id
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
          module.ntc_vpc_central_endpoints.customer_managed_prefix_lists["onprem-dns-servers"].id
        ]
        # (optional) allow outbound resolver to forward to inbound resolver
        self = true
      },
      {
        protocol = "udp"
        # add cidrs or prefix list of on-premises dns servers (if omitted default is 0.0.0.0/0)
        cidr_blocks = []
        prefix_list_ids = [
          module.ntc_vpc_central_endpoints.customer_managed_prefix_lists["onprem-dns-servers"].id
        ]
        # (optional) allow outbound resolver to forward to inbound resolver
        self = true
      }
    ]
  }

  resolver_rules = [
    {
      domain_name = "domain.onprem"
      rule_name   = "forward onprem dns traffic"
      rule_type   = "FORWARD"
      vpc_ids = [
        module.ntc_vpc_central_endpoints.vpc_id
      ]
      target_ips = [
        # add ips of on-premises dns servers (default port is 53)
        "192.168.8.8",
        "192.168.9.9"
      ]
      # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "945766593056"]
      # ram_share_allow_external_principals = false
    }
  ]

  providers = {
    aws = aws.euc1
  }
}
