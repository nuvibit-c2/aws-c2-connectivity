# ---------------------------------------------------------------------------------------------------------------------
# ¦ PLACEHOLDER: NTC-CORE-NETWORK
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "core" {
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

resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.core.id

  tags = {
    "Name" = "tgw-route-table-hub"
  }
}

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.core.id

  tags = {
    "Name" = "tgw-route-table-spoke"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK
# ---------------------------------------------------------------------------------------------------------------------
# module "ntc_core_network" {
#   source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network?ref=beta"



#   providers = {
#     aws = aws.euc1
#   }
# }