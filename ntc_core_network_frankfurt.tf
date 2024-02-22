# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_euc1" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network?ref=beta"

  transit_gateway = {
    name                            = "tgw-core-frankfurt"
    description                     = "core network in frankfurt"
    amazon_side_asn                 = 64512
    default_route_table_association = false
    default_route_table_propagation = false
    dns_support                     = true
    multicast_support               = false
    vpn_ecmp_support                = true
    cidr_blocks                     = []
    route_table_names = [
      "tgw-core-rtb-hub",
      "tgw-core-rtb-spoke-prod",
      "tgw-core-rtb-spoke-dev",
      "tgw-core-rtb-spoke-int",
    ]
    # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
    auto_accept_shared_attachments      = true
    ram_share_principals                = []
    ram_share_allow_external_principals = false
  }

  providers = {
    aws = aws.euc1
  }
}

moved {
  from = module.ntc_core_network
  to   = module.ntc_core_network_euc1
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK - PEERING
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_euc1_peering" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/transit-gateway-peering?ref=beta"

  # the transit gateway accepting a peering is called 'accepter'
  # accepter transit gateway can accept peerings with multiple transit gateways in different regions and/or accounts
  # transit gateway peers need to initialize the peering beforehand and are therefore called 'requester'
  transit_gateway_accept_peerings = [
    module.ntc_core_network_euc2_peering.transit_gateway_peering_info_for_accepter["tgw-core-frankfurt"]
  ]

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK - CUSTOM ROUTES
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_custom_routes" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/custom-routes?ref=beta"

  # add custom routes for more flexibility and full control (e.g. firewall deployment)
  transit_gateway_custom_routes = [
    {
      route_identifier = "route_prod_spoke_to_central_endpoints"
      # route table where custom route will be be added
      route_table_id = module.ntc_core_network_euc1.transit_gateway_route_table_ids["tgw-core-rtb-spoke-prod"]
      # transit gateway attachment (Peering, VPC, Direct Connect, VPN) where traffic should be forwarded to
      attachment_id = module.ntc_vpc_central_endpoints.transit_gateway_vpc_attachement_id
      # set to true to drop specific traffic. cannot be combined with 'attachment_id'
      blackhole = false
      # what is the destination of the traffic that should be controlled by this route?
      # a single destination type is required and cannot combine multiple destination types
      destination = {
        cidr_block     = "10.100.10.0/24"
        prefix_list_id = ""
      }
    },
    {
      route_identifier = "blackhole_dev_spoke_to_central_endpoints"
      route_table_id   = module.ntc_core_network_euc1.transit_gateway_route_table_ids["tgw-core-rtb-spoke-dev"]
      attachment_id    = ""
      blackhole        = true
      destination = {
        cidr_block     = "10.100.10.0/24"
        prefix_list_id = ""
      }
    },
    {
      route_identifier = "route_int_spoke_to_central_endpoints"
      route_table_id   = module.ntc_core_network_euc1.transit_gateway_route_table_ids["tgw-core-rtb-spoke-int"]
      attachment_id    = module.ntc_vpc_central_endpoints.transit_gateway_vpc_attachement_id
      blackhole        = false
      destination = {
        cidr_block     = "10.100.10.0/24"
        prefix_list_id = ""
      }
    }
  ]

  providers = {
    aws = aws.euc1
  }
}
