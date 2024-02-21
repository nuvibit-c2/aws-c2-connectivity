# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_euc2" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network?ref=beta"

  transit_gateway = {
    name                            = "tgw-core-zurich"
    description                     = "core network in zurich"
    amazon_side_asn                 = 64513 # good practice to use unique asn in multi region
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
    aws = aws.euc2
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK - CUSTOM ROUTES
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_custom_routes_euc2" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/custom-routes?ref=beta"

  # add custom routes for more flexibility and full control (e.g. firewall deployment)
  transit_gateway_custom_routes = [
    {
      route_identifier = "blackhole_dev_spoke_to_central_endpoints"
      route_table_id   = module.ntc_core_network_euc2.transit_gateway_route_table_ids["tgw-core-rtb-spoke-dev"]
      attachment_id    = "" # TODO: forward to peering attachement for tgw_frankfurt
      blackhole        = true
      destination = {
        cidr_block     = "10.100.0.0/16"
        prefix_list_id = ""
      }
    }
  ]

  providers = {
    aws = aws.euc2
  }
}
