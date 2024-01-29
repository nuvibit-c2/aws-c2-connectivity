# ---------------------------------------------------------------------------------------------------------------------
# ¦ PLACEHOLDER: NTC-CORE-NETWORK
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "ntc_core" {
  description                     = "core network"
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  multicast_support               = "disable"
  transit_gateway_cidr_blocks     = []
  vpn_ecmp_support                = "enable"

  tags = {
    "Name" = "tgw-core"
  }
}

resource "aws_ec2_transit_gateway_route_table" "ntc_hub" {
  transit_gateway_id = aws_ec2_transit_gateway.ntc_core.id

  tags = {
    "Name" = "tgw-route-table-hub"
  }
}

resource "aws_ec2_transit_gateway_route_table" "ntc_spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.ntc_core.id

  tags = {
    "Name" = "tgw-route-table-spoke"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network?ref=beta"

  transit_gateway = {
    name                            = "tgw-core-frankfurt"
    description                     = "core network in frankfurt"
    amazon_side_asn                 = 64512
    default_route_table_association = true
    default_route_table_propagation = true
    dns_support                     = true
    multicast_support               = false
    vpn_ecmp_support                = true
    cidr_blocks                     = []
    route_table_names = [
      "tgw-route-table-hub",
      "tgw-route-table-spoke-prod",
      "tgw-route-table-spoke-dev",
      "tgw-route-table-spoke-int",
    ]
    # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
    auto_accept_shared_attachments      = false
    ram_share_principals                = []
    ram_share_allow_external_principals = false
  }

  providers = {
    aws = aws.euc1
  }
}
