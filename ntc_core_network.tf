# ---------------------------------------------------------------------------------------------------------------------
# ¦ WILL BE REPLACED WITH A MODUlE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "core" {
  description = "core network"
}

resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.core.id
}

resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.core.id
}
