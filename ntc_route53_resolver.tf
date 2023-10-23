# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # for hybrid dns route53 resolver endpoints are required for inbound and outbound
  # https://docs.aws.amazon.com/whitepapers/latest/hybrid-cloud-dns-options-for-vpc/route-53-resolver-endpoints-and-forwarding-rules.html

  route53_resolver = {
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
          static_ip = null
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
          static_ip = null
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
          cidr_blocks = [
            # add cidrs of on-premises dns servers (by default 0.0.0.0/0)
            "192.168.8.8/32",
            "192.168.9.9/32"
          ]
          # (optional) allow outbound resolver to forward to inbound resolver
          self = true
        },
        {
          protocol = "udp"
          cidr_blocks = [
            # add cidrs of on-premises dns servers (by default 0.0.0.0/0)
            "192.168.8.8/32",
            "192.168.9.9/32"
          ]
          # (optional) allow outbound resolver to forward to inbound resolver
          self = true
        }
      ]

      egress_rules = [
        {
          protocol = "tcp"
          cidr_blocks = [
            # add cidrs of on-premises dns servers (by default 0.0.0.0/0)
            "192.168.8.8/32",
            "192.168.9.9/32"
          ]
          # (optional) allow outbound resolver to forward to inbound resolver
          self = true
        },
        {
          protocol = "udp"
          cidr_blocks = [
            # add cidrs of on-premises dns servers (by default 0.0.0.0/0)
            "192.168.8.8/32",
            "192.168.9.9/32"
          ]
          # (optional) allow outbound resolver to forward to inbound resolver
          self = true
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

  resolver_endpoint_inbound        = local.route53_resolver.resolver_endpoint_inbound
  resolver_endpoint_outbound       = local.route53_resolver.resolver_endpoint_outbound
  resolver_endpoint_security_group = local.route53_resolver.resolver_endpoint_security_group

  providers = {
    aws = aws.euc1
  }
}
