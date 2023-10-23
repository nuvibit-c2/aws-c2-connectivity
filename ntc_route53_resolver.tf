# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # for hybrid dns route53 resolver endpoints are required for inbound and outbound
  # https://docs.aws.amazon.com/whitepapers/latest/hybrid-cloud-dns-options-for-vpc/route-53-resolver-endpoints-and-forwarding-rules.html

  route53_resolver = {
    # ROUTE53 INBOUND RESOLVER
    # configure conditional dns forwarding from on-premise dns servers to these endpoints (e.g. *.cloud.mydomain.internal)
    resolver_endpoints_inbound_config = {
      create_endpoints = true
      resolver_name    = "r53-inbound-resolver"
      # (optional) you can attach existing security groups instead of creating a new one
      security_group_ids = []
      subnets = [for index, id in module.ntc_vpc_central_endpoints.subnet_ids["hybrid-private"] :
        {
          subnet_id = id
          # (optional but recommended) set a static ip for the resolver endpoint
          static_ip = null
        }
      ]
    }

    # for inbound resolver only inbound traffic is allowed (by default tcp/udp 53)
    resolver_endpoints_inbound_security_group = {
      create_security_group = true
      name                  = "r53-inbound-resolver"
      description           = "DNS traffic to inbound resolvers"
      vpc_id                = module.ntc_vpc_central_endpoints.vpc_id
      ingress_rules = [
        {
          protocol = "tcp"
          cidr_blocks = [
            # add cidrs of on-premises dns servers (by default 0.0.0.0/0)
            "192.168.8.8/32",
            "192.168.9.9/32"
          ]
          # (optional) allow outbound resolver to forward to inbound resolver
          outbound_to_inbound_forwarding = true
        },
        {
          protocol = "udp"
          cidr_blocks = [
            # add cidrs of on-premises dns servers (by default 0.0.0.0/0)
            "192.168.8.8/32",
            "192.168.9.9/32"
          ]
          # (optional) allow outbound resolver to forward to inbound resolver
          outbound_to_inbound_forwarding = true
        }
      ]
    }

    # ROUTE53 OUTBOUND RESOLVER
    resolver_endpoints_outbound_config = {
      create_endpoints = true
      resolver_name    = "r53-outbound-resolver"
      # (optional) you can attach existing security groups instead of creating a new one
      security_group_ids = []
      subnets = [for index, id in module.ntc_vpc_central_endpoints.subnet_ids["hybrid-private"] :
        {
          subnet_id = id
          # (optional but recommended) set a static ip for the resolver endpoint
          static_ip = null
        }
      ]
    }

    # for outbound resolver only outbound traffic is allowed (by default tcp/udp 53)
    resolver_endpoints_outbound_security_group = {
      create_security_group = true
      name                  = "r53-outbound-resolver"
      description           = "DNS traffic from outbound resolvers"
      vpc_id                = module.ntc_vpc_central_endpoints.vpc_id
      egress_rules = [
        {
          protocol = "tcp"
          cidr_blocks = [
            # add cidrs of on-premises dns servers (by default 0.0.0.0/0)
            "192.168.8.8/32",
            "192.168.9.9/32"
          ]
          # (optional) allow outbound resolver to forward to inbound resolver
          outbound_to_inbound_forwarding = true
        },
        {
          protocol = "udp"
          cidr_blocks = [
            # add cidrs of on-premises dns servers (by default 0.0.0.0/0)
            "192.168.8.8/32",
            "192.168.9.9/32"
          ]
          # (optional) allow outbound resolver to forward to inbound resolver
          outbound_to_inbound_forwarding = true
        }
      ]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ROUTE53
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_route53_resolver" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/resolver?ref=beta"

  resolver_endpoints_inbound_config          = local.route53_resolver.resolver_endpoints_inbound_config
  resolver_endpoints_outbound_config         = local.route53_resolver.resolver_endpoints_outbound_config
  resolver_endpoints_inbound_security_group  = local.route53_resolver.resolver_endpoints_inbound_security_group
  resolver_endpoints_outbound_security_group = local.route53_resolver.resolver_endpoints_outbound_security_group

  providers = {
    aws = aws.euc1
  }
}
