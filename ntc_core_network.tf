# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network" {
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

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK - CUSTOM ROUTES
# ---------------------------------------------------------------------------------------------------------------------
# module "ntc_core_network_custom_routes" {
#   source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/custom-routes?ref=beta"

#   # add custom routes for more flexibility and full control (e.g. firewall deployment)
#   custom_routes = [
#     {
#       # route table where custom route will be be added
#       route_table_id = module.ntc_vpc_prod_stage.route_table_ids["cloudonly-private"][0]
#       # what is the destination of the traffic that should be controlled by this route?
#       # a single destination type is required and cannot combine multiple destination types
#       destination = {
#         cidr_block      = "10.100.10.0/24"
#         ipv6_cidr_block = ""
#         prefix_list_id  = ""
#       }
#       # what is the target of the traffic that should be controlled by this route?
#       # a single target type is required and cannot combine multiple target types
#       target = {
#         carrier_gateway_id          = ""
#         core_network_arn            = ""
#         ipv6_egress_only_gateway_id = ""
#         internet_gateway_id         = ""
#         transit_gateway_id          = ""
#         virtual_private_gateway_id  = ""
#         vpc_peering_connection_id   = ""
#         nat_gateway_id              = ""
#         network_interface_id        = "eni-068b5ccd7f7b7cfd3"
#         vpc_endpoint_id             = ""
#       }
#     },
#     {
#       route_table_id = module.ntc_vpc_prod_stage.route_table_ids["cloudonly-private"][1]
#       destination = {
#         cidr_block = "10.100.10.0/24"
#       }
#       target = {
#         network_interface_id = "eni-0ca9af96faf51d443"
#       }
#     },
#     {
#       route_table_id = module.ntc_vpc_prod_stage.route_table_ids["cloudonly-private"][2]
#       destination = {
#         cidr_block = "10.100.10.0/24"
#       }
#       target = {
#         network_interface_id = "eni-0e55b3e0b04ee1824"
#       }
#     }
#   ]

#   providers = {
#     aws = aws.euc1
#   }
# }
