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

  # transit gateway flow logs can be delivered to s3, cloudwatch and kinesis-data-firehose.
  # it is possible to send flow logs from a single transit gateway to multiple targets in parallel e.g. s3 + cloudwatch
  transit_gateway_flow_log_destinations = [
    {
      destination_type = "s3"
      destination_arn  = try(local.ntc_parameters["log-archive"]["log_bucket_arns"]["transit_gateway_flow_logs"], "")
      # decide wether to capture ALL, only ACCEPT or only REJECT traffic
      traffic_type = "ALL"
      # interval can be 60 seconds (1min) or 600 seconds (10min)
      max_aggregation_interval = 600
      # log format fields can be customized
      # https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html#flow-logs-default
      # log_format = "$${account-id} $${action} $${bytes} $${dstaddr} $${dstport} $${end} $${instance-id} $${interface-id} $${log-status} $${packets} $${pkt-dstaddr} $${pkt-srcaddr} $${protocol} $${srcaddr} $${srcport} $${start} $${subnet-id} $${tcp-flags} $${type} $${version} $${vpc-id}"
    },
    # {
    #   destination_type = "cloud-watch-logs"
    #   # cloudwatch log group will be created if destination_arn is omitted
    #   destination_arn = ""
    #   cloudwatch_options = {
    #     iam_role_arn = "CLOUDWATCH_IAM_ROLE_ARN"
    #   }
    # },
    # {
    #   destination_type = "kinesis-data-firehose"
    #   destination_arn = "KINESIS_DATA_FIREHOSE_ARN"
    # }
  ]

  providers = {
    aws = aws.euc2
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK - PEERING
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_euc2_peering" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/transit-gateway-peering?ref=beta"

  # the transit gateway initiating peering is called 'requester'
  # requester transit gateway can initialize peerings with multiple transit gateways in different regions and/or accounts
  # transit gateway peers need to accept the peering and are therefore called 'accepter'
  transit_gateway_create_peerings = {
    requester_transit_gateway_name = module.ntc_core_network_euc2.transit_gateway_name
    requester_transit_gateway_id   = module.ntc_core_network_euc2.transit_gateway_id
    accepter_transit_gateways = [
      # {
      #   peer_transit_gateway_name = ""
      #   peer_transit_gateway_id   = ""
      #   peer_account_id           = ""
      #   peer_region               = ""
      # }
      module.ntc_core_network_euc1.transit_gateway_peering_info_for_creator
    ]
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
