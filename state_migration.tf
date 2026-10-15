# =====================================================================================================================
# STATE MIGRATIONS - v1.x to v2.x
# =====================================================================================================================
# These moved blocks ensure Terraform state is updated without recreating resources
# Run: terraform plan - should show only "moved" operations (no creates/destroys)
# After successful migration, this file can be deleted

# -------------------------------------------------------------------------------------------------------------------
# ROUTE53 - DNSSEC
# -------------------------------------------------------------------------------------------------------------------
moved {
  from = module.ntc_route53_nuvibit_dev_dnssec.aws_kms_alias.ntc_dnssec["ksk-1"]
  to   = module.ntc_route53_nuvibit_dev.module.dnssec[0].aws_kms_alias.ntc_dnssec["ksk-1"]
}

moved {
  from = module.ntc_route53_nuvibit_dev_dnssec.aws_kms_key.ntc_dnssec["ksk-1"]
  to   = module.ntc_route53_nuvibit_dev.module.dnssec[0].aws_kms_key.ntc_dnssec["ksk-1"]
}

moved {
  from = module.ntc_route53_nuvibit_dev_dnssec.aws_route53_hosted_zone_dnssec.ntc_dnssec["ksk-1"]
  to   = module.ntc_route53_nuvibit_dev.module.dnssec[0].aws_route53_hosted_zone_dnssec.ntc_dnssec["ksk-1"]
}

moved {
  from = module.ntc_route53_nuvibit_dev_dnssec.aws_route53_key_signing_key.ntc_dnssec["ksk-1"]
  to   = module.ntc_route53_nuvibit_dev.module.dnssec[0].aws_route53_key_signing_key.ntc_dnssec["ksk-1"]
}

# -------------------------------------------------------------------------------------------------------------------
# ROUTE53 - QUERY LOGS
# -------------------------------------------------------------------------------------------------------------------
moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_route53_query_log.ntc_query_log
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_route53_query_log.ntc_query_log
}

moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_kms_key.ntc_query_log_encryption[0]
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_kms_key.ntc_query_log_encryption[0]
}

moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_kms_alias.ntc_query_log_encryption[0]
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_kms_alias.ntc_query_log_encryption[0]
}

moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_cloudwatch_log_resource_policy.ntc_query_log
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_cloudwatch_log_resource_policy.ntc_query_log
}

moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_cloudwatch_log_group.ntc_query_log
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_cloudwatch_log_group.ntc_query_log
}

# -------------------------------------------------------------------------------------------------------------------
# CORE NETWORK - FRANKFURT (eu-central-1)
# -------------------------------------------------------------------------------------------------------------------
# Transit Gateway
moved {
  from = module.ntc_core_network_frankfurt.aws_ec2_transit_gateway.ntc_core[0]
  to   = module.ntc_core_network.aws_ec2_transit_gateway.ntc_core["tgw-core-frankfurt"]
}

# Transit Gateway Route Tables
moved {
  from = module.ntc_core_network_frankfurt.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-hub"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-frankfurt/tgw-core-rtb-hub"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-onprem"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-frankfurt/tgw-core-rtb-onprem"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-spoke-dev"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-frankfurt/tgw-core-rtb-spoke-dev"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-spoke-int"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-frankfurt/tgw-core-rtb-spoke-int"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-spoke-prod"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-frankfurt/tgw-core-rtb-spoke-prod"]
}

# Direct Connect
moved {
  from = module.ntc_core_network_frankfurt.aws_dx_lag.ntc_dx["dx-con-frankfurt"]
  to   = module.ntc_core_network.aws_dx_lag.ntc_dx["eu-central-1/dx-con-frankfurt"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_ec2_transit_gateway_route_table_association.ntc_dx["tgw-core-frankfurt/dx-gateway"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table_association.ntc_dx["eu-central-1/tgw-core-frankfurt/dx-gateway"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_dx_gateway_association.ntc_dx["tgw-core-frankfurt/dx-gateway"]
  to   = module.ntc_core_network.aws_dx_gateway_association.ntc_dx["eu-central-1/tgw-core-frankfurt/dx-gateway"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_dx_gateway.ntc_dx["dx-gateway"]
  to   = module.ntc_core_network.aws_dx_gateway.ntc_dx["dx-gateway"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_dx_connection.ntc_dx["dx-con-frankfurt/1"]
  to   = module.ntc_core_network.aws_dx_connection.ntc_dx["eu-central-1/dx-con-frankfurt/1"]
}

# VPN
moved {
  from = module.ntc_core_network_frankfurt.aws_vpn_connection.ntc_vpn["i7_frankfurt_vpn1"]
  to   = module.ntc_core_network.aws_vpn_connection.ntc_vpn["eu-central-1/i7_frankfurt_vpn1"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_ec2_transit_gateway_route_table_propagation.ntc_vpn["i7_frankfurt_vpn1/tgw-core-rtb-hub"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table_propagation.ntc_vpn["eu-central-1/i7_frankfurt_vpn1/tgw-core-rtb-hub"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_customer_gateway.ntc_vpn["i7_frankfurt"]
  to   = module.ntc_core_network.aws_customer_gateway.ntc_vpn["eu-central-1/i7_frankfurt"]
}

# RAM Resource Sharing
moved {
  from = module.ntc_core_network_frankfurt.aws_ram_resource_share.ntc_tgw_share[0]
  to   = module.ntc_core_network.aws_ram_resource_share.ntc_tgw_share["tgw-core-frankfurt"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_ram_resource_association.ntc_tgw_share[0]
  to   = module.ntc_core_network.aws_ram_resource_association.ntc_tgw_share["tgw-core-frankfurt"]
}

moved {
  from = module.ntc_core_network_frankfurt.aws_ram_principal_association.ntc_tgw_share["ou-52tn-aparqzit"]
  to   = module.ntc_core_network.aws_ram_principal_association.ntc_tgw_share["tgw-core-frankfurt/ou-52tn-aparqzit"]
}

# Flow Logs
moved {
  from = module.ntc_core_network_frankfurt.module.flow_logs["s3"].aws_flow_log.ntc_flow_logs
  to   = module.ntc_core_network.module.flow_logs["tgw-core-frankfurt/s3"].aws_flow_log.ntc_flow_logs
}

# -------------------------------------------------------------------------------------------------------------------
# CORE NETWORK - ZURICH (eu-central-2)
# -------------------------------------------------------------------------------------------------------------------
# Transit Gateway
moved {
  from = module.ntc_core_network_zurich.aws_ec2_transit_gateway.ntc_core[0]
  to   = module.ntc_core_network.aws_ec2_transit_gateway.ntc_core["tgw-core-zurich"]
}

# Transit Gateway Route Tables
moved {
  from = module.ntc_core_network_zurich.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-hub"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-zurich/tgw-core-rtb-hub"]
}

moved {
  from = module.ntc_core_network_zurich.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-onprem"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-zurich/tgw-core-rtb-onprem"]
}

moved {
  from = module.ntc_core_network_zurich.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-spoke-dev"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-zurich/tgw-core-rtb-spoke-dev"]
}

moved {
  from = module.ntc_core_network_zurich.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-spoke-int"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-zurich/tgw-core-rtb-spoke-int"]
}

moved {
  from = module.ntc_core_network_zurich.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-rtb-spoke-prod"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table.ntc_core["tgw-core-zurich/tgw-core-rtb-spoke-prod"]
}

# RAM Resource Sharing
moved {
  from = module.ntc_core_network_zurich.aws_ram_resource_share.ntc_tgw_share[0]
  to   = module.ntc_core_network.aws_ram_resource_share.ntc_tgw_share["tgw-core-zurich"]
}

moved {
  from = module.ntc_core_network_zurich.aws_ram_resource_association.ntc_tgw_share[0]
  to   = module.ntc_core_network.aws_ram_resource_association.ntc_tgw_share["tgw-core-zurich"]
}

moved {
  from = module.ntc_core_network_zurich.aws_ram_principal_association.ntc_tgw_share["ou-52tn-aparqzit"]
  to   = module.ntc_core_network.aws_ram_principal_association.ntc_tgw_share["tgw-core-zurich/ou-52tn-aparqzit"]
}

# Flow Logs
moved {
  from = module.ntc_core_network_zurich.module.flow_logs["s3"].aws_flow_log.ntc_flow_logs
  to   = module.ntc_core_network.module.flow_logs["tgw-core-zurich/s3"].aws_flow_log.ntc_flow_logs
}

# -------------------------------------------------------------------------------------------------------------------
# CORE NETWORK - PEERING (FRANKFURT <-> ZURICH)
# -------------------------------------------------------------------------------------------------------------------
# Peering Attachment (creator side - Frankfurt)
moved {
  from = module.ntc_core_network_frankfurt_peering.aws_ec2_transit_gateway_peering_attachment.ntc_peering["tgw-core-zurich"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_peering_attachment.ntc_peering["tgw-core-frankfurt:tgw-core-zurich"]
}

moved {
  from = module.ntc_core_network_frankfurt_peering.aws_ec2_transit_gateway_route_table_association.ntc_peering_acceptor["tgw-core-zurich"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table_association.ntc_peering_creator["tgw-core-frankfurt:tgw-core-zurich"]
}

# Peering Attachment (accepter side - Zurich)
moved {
  from = module.ntc_core_network_zurich_peering.aws_ec2_transit_gateway_peering_attachment_accepter.ntc_peering["tgw-core-frankfurt"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_peering_attachment_accepter.ntc_peering["tgw-core-frankfurt:tgw-core-zurich"]
}

moved {
  from = module.ntc_core_network_zurich_peering.aws_ec2_transit_gateway_route_table_association.ntc_peering_creator["tgw-core-frankfurt"]
  to   = module.ntc_core_network.aws_ec2_transit_gateway_route_table_association.ntc_peering_acceptor["tgw-core-frankfurt:tgw-core-zurich"]
}
