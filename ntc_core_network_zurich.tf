# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_zurich" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network?ref=beta"

  # -------------------------------------------------------------------------------------------------------------------
  # ¦ TRANSIT GATEWAY
  # -------------------------------------------------------------------------------------------------------------------
  transit_gateway = {
    name                            = "tgw-core-zurich"
    description                     = "core network in zurich"
    amazon_side_asn                 = 64513
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
      # interval must be 60 seconds (1min)
      max_aggregation_interval = 60
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

  # -------------------------------------------------------------------------------------------------------------------
  # ¦ DIRECT CONNECT
  # -------------------------------------------------------------------------------------------------------------------
  direct_connect = {
    # direct connect gateway is a globally available resource to connect to the VPCs or VPNs that are attached to a transit gateway
    # you can connect up to 6 transit gateways in one or more regions with a single direct connect gateway
    dx_gateways = []
    # associate direct connect gateway with transit gateway defined in 'transit_gateway'
    transit_gateway_associations = [
      {
        # either reference the direct connect gateway defined in 'direct_connect.dx_gateways'
        dx_gateway_name = "dx-gateway"
        # or reference the id of an existing direct connect gateway
        dx_gateway_id = module.ntc_core_network_frankfurt.dx_gateway_ids_by_name["dx-gateway"]
        # reference transit gateway route table defined in 'transit_gateway'
        transit_gateway_association_with_route_table_name = "tgw-core-rtb-hub"
        # only the allowed prefixes entered will be advertised to on-premises and cannot be overlapping across transit gateways
        allowed_prefixes = ["10.200.10.0/24", "10.200.20.0/24", "10.200.30.0/24"]
      }
    ]
    # dedicated network connections between on-premises and aws direct connect locations
    dx_dedicated_connections = [
      # {
      #   name = "dx-con-frankfurt"
      #   # bandwidth can be one of 1, 2, 3, 4, 10, 20, 30, 40, 100, 200, 300, 400 Gpbs
      #   # upgrading bandwidth without downtime in ranges 1-4, 10-40 or 100-400
      #   # upgrading bandwidth from 1 Gpbs to 10 Gpbs will recreate connections
      #   # WARNING: recreating connections will cause downtime if no failover is availble (e.g. secondary direct connect or vpn)
      #   bandwidth_in_gpbs = 1
      #   location          = "EqFA5"
      #   provider_name     = "Equinix"
      #   macsec_support    = false
      #   # avoid deleting connection when destroyed and instead remove from the Terraform state
      #   skip_destroy = false
      #   # private virtual interfaces can be used to access a VPC using private IP addresses
      #   # public virtual interfaces can access all aws public services using public IP addresses
      #   # transit virtual interfaces should be used to access one or more transit gateways associated with direct connect gateways (recommended)
      #   virtual_interfaces = [
      #     {
      #       name = "dx-vif-transit-frankfurt"
      #       type = "transit"
      #       # either reference the direct connect gateway defined in 'direct_connect.dx_gateways'
      #       dx_gateway_name = "dx-gateway"
      #       # or reference the id of an existing direct connect gateway
      #       dx_gateway_id     = ""
      #       vlan              = 100
      #       address_family    = "ipv4"
      #       customer_side_asn = 65352
      #       bgp_auth_key      = null
      #       mtu               = 1500
      #       sitelink_enabled  = false
      #       # the destination IPv4 CIDR address to which AWS should send traffic (default is a /29 from 169.254.0.0/16)
      #       customer_peer_ip = "10.0.0.1/30"
      #       # the IPv4 CIDR address to use to send traffic to AWS (default is a /29 from 169.254.0.0/16)
      #       amazon_peer_ip = "10.0.0.2/30"
      #     }
      #   ]
      # }
    ]
  }

  providers = {
    aws = aws.euc2
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK - PEERING (FRA-ZRH)
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_zurich_peering" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/transit-gateway-peering?ref=beta"

  # the transit gateway initiating peering is called 'requester'
  # requester transit gateway can initialize peerings with multiple transit gateways in different regions and/or accounts
  # transit gateway peers need to accept the peering and are therefore called 'accepter'
  transit_gateway_create_peerings = {
    requester_transit_gateway_name = module.ntc_core_network_zurich.transit_gateway_name
    requester_transit_gateway_id   = module.ntc_core_network_zurich.transit_gateway_id
    accepter_transit_gateways = [
      # {
      #   peer_transit_gateway_name = ""
      #   peer_transit_gateway_id   = ""
      #   peer_account_id           = ""
      #   peer_region               = ""
      # }
      module.ntc_core_network_frankfurt.transit_gateway_peering_info_for_creator
    ]
  }

  providers = {
    aws = aws.euc2
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK - CUSTOM ROUTES
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_zurich_custom_routes" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/custom-routes?ref=beta"

  # add custom routes for more flexibility and full control (e.g. firewall deployment)
  transit_gateway_custom_routes = [
    {
      route_identifier = "dev_spoke_to_frankfurt"
      route_table_id   = module.ntc_core_network_zurich.transit_gateway_route_table_ids["tgw-core-rtb-spoke-dev"]
      attachment_id    = module.ntc_core_network_zurich_peering.transit_gateway_attachment_id_by_peer_transit_gateway_name["tgw-core-frankfurt"]
      blackhole        = false
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
