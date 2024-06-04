# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_frankfurt" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network?ref=1.1.1"

  # -------------------------------------------------------------------------------------------------------------------
  # ¦ TRANSIT GATEWAY
  # -------------------------------------------------------------------------------------------------------------------
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
      "tgw-core-rtb-onprem",
    ]
    # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
    auto_accept_shared_attachments = true
    ram_share_principals = [
      local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads"]
    ]
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
    #   # cloudwatch log group will be created if 'destination_arn' is omitted
    #   destination_arn = ""
    #   cloudwatch_options = {
    #     use_existing_kms_key = false
    #     kms_key_arn          = ""
    #     # iam role is required when an existing log group is defined in 'destination_arn'
    #     iam_role_arn = ""
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
    dx_gateways = [
      {
        name            = "dx-gateway"
        amazon_side_asn = 65500
      }
    ]
    # associate direct connect gateway with transit gateway defined in 'transit_gateway'
    transit_gateway_associations = [
      {
        # either reference the direct connect gateway defined in 'direct_connect.dx_gateways'
        dx_gateway_name = "dx-gateway"
        # or reference the id of an existing direct connect gateway
        dx_gateway_id = ""
        # reference transit gateway route table defined in 'transit_gateway'
        transit_gateway_association_with_route_table_name = "tgw-core-rtb-onprem"
        transit_gateway_propagation_to_route_table_names = [
          "tgw-core-rtb-hub",
          "tgw-core-rtb-spoke-prod",
          "tgw-core-rtb-spoke-dev",
          "tgw-core-rtb-spoke-int",
        ]
        # only the allowed prefixes entered will be advertised to on-premises and cannot be overlapping across transit gateways
        allowed_prefixes = ["10.100.10.0/24", "10.100.20.0/24", "10.100.30.0/24"]
      }
    ]
    # dedicated network connections between on-premises and aws direct connect locations
    dx_dedicated_connections = [
      {
        name = "dx-con-frankfurt"
        # bandwidth can be one of 1, 2, 3, 4, 10, 20, 30, 40, 100, 200, 300, 400 Gpbs
        # upgrading bandwidth without downtime in ranges 1-4, 10-40 or 100-400
        # upgrading bandwidth from 1 Gpbs to 10 Gpbs will recreate connections
        # WARNING: recreating connections will cause downtime if no failover is availble (e.g. secondary direct connect or vpn)
        bandwidth_in_gpbs = 1
        # associated region of direct connect location must match with provider region
        # https://aws.amazon.com/directconnect/locations/
        location_name  = "Equinix FR5, Frankfurt, DEU"
        provider_name  = "Equinix, Inc."
        macsec_support = false
        # avoid deleting connection when destroyed and instead remove from the Terraform state
        skip_destroy = false
        # private virtual interfaces can be used to access a VPC using private IP addresses
        # public virtual interfaces can access all aws public services using public IP addresses
        # transit virtual interfaces should be used to access one or more transit gateways associated with direct connect gateways (recommended)
        virtual_interfaces = [
          {
            name = "dx-vif-transit-frankfurt"
            type = "transit"
            # either reference the direct connect gateway defined in 'direct_connect.dx_gateways'
            dx_gateway_name = "dx-gateway"
            # or reference the id of an existing direct connect gateway
            dx_gateway_id     = ""
            vlan              = 100
            address_family    = "ipv4"
            customer_side_asn = 65352
            bgp_auth_key      = null
            mtu               = 1500
            sitelink_enabled  = false
            # the destination IPv4 CIDR address to which AWS should send traffic (default is a /29 from 169.254.0.0/16)
            customer_peer_ip = "10.0.0.1/30"
            # the IPv4 CIDR address to use to send traffic to AWS (default is a /29 from 169.254.0.0/16)
            amazon_peer_ip = "10.0.0.2/30"
          }
        ]
      }
    ]
  }

  # -------------------------------------------------------------------------------------------------------------------
  # ¦ S2S VPN
  # -------------------------------------------------------------------------------------------------------------------
  virtual_private_network = {
    # a customer gateway device is a physical or software appliance that you own or manage in your on-premises network
    customer_gateways = [
      {
        name              = "i7_zrh"
        device_name       = "i7zrhr1"
        customer_side_asn = 65000
        ip_address        = "77.109.180.4"
        certificate_arn   = null
      }
    ]
    # VPN connections will be automatically attached to core network transit gateway defined in 'transit_gateway'
    # a VPN connection offers two VPN tunnels between a virtual private gateway or transit gateway on the AWS side, and a customer gateway on the on-premises side
    # maximum bandwidth per VPN tunnel is 1.25 Gbps but you can add additional vpn connections to increase bandwith when ECMP is enabled on transit gateway
    vpn_connections = [
      {
        name = "i7_zrh_vpn1"
        # reference customer gateway defined in 'customer_gateways'
        customer_gateway_name = "i7_zrh"
        # reference transit gateway route table defined in 'transit_gateway'
        transit_gateway_association_with_route_table_name = "tgw-core-rtb-onprem"
        transit_gateway_propagation_to_route_table_names = [
          "tgw-core-rtb-hub",
          "tgw-core-rtb-spoke-prod",
          "tgw-core-rtb-spoke-dev",
          "tgw-core-rtb-spoke-int",
        ]
        # by default dynamic routing with bgp is enabled
        # static routes need to be added to transit gateway route table
        static_routes_only      = false
        enable_acceleration     = false
        address_family          = "ipv4"
        local_network_cidr      = "0.0.0.0/0"
        remote_network_cidr     = "0.0.0.0/0"
        outside_ip_address_type = "PublicIpv4"
        # attachment_id required when 'outside_ip_address_type' is 'PrivateIpv4'
        transport_transit_gateway_attachment_id = ""
        # (optional) ipsec tunnel1 configuration
        tunnel1_options = {
          inside_cidr                     = null
          preshared_key                   = null
          dpd_timeout_action              = "clear"
          dpd_timeout_seconds             = 30
          enable_tunnel_lifecycle_control = false
          ike_versions                    = ["ikev1", "ikev2"]
          phase1_dh_group_numbers         = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
          phase1_encryption_algorithms    = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
          phase1_integrity_algorithms     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
          phase1_lifetime_seconds         = 28800
          phase2_dh_group_numbers         = [2, 5, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
          phase2_encryption_algorithms    = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
          phase2_integrity_algorithms     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
          phase2_lifetime_seconds         = 3600
          rekey_fuzz_percentage           = 100
          rekey_margin_time_seconds       = 540
          replay_window_size              = 1024
          startup_action                  = "add"
          cloudwatch_log_options = {
            enabled           = false
            log_group_arn     = ""
            log_output_format = "json"
          }
        }
        # (optional) ipsec tunnel2 configuration
        tunnel2_options = {
          inside_cidr                     = null
          preshared_key                   = null
          dpd_timeout_action              = "clear"
          dpd_timeout_seconds             = 30
          enable_tunnel_lifecycle_control = false
          ike_versions                    = ["ikev1", "ikev2"]
          phase1_dh_group_numbers         = [2, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
          phase1_encryption_algorithms    = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
          phase1_integrity_algorithms     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
          phase1_lifetime_seconds         = 28800
          phase2_dh_group_numbers         = [2, 5, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
          phase2_encryption_algorithms    = ["AES128", "AES256", "AES128-GCM-16", "AES256-GCM-16"]
          phase2_integrity_algorithms     = ["SHA1", "SHA2-256", "SHA2-384", "SHA2-512"]
          phase2_lifetime_seconds         = 3600
          rekey_fuzz_percentage           = 100
          rekey_margin_time_seconds       = 540
          replay_window_size              = 1024
          startup_action                  = "add"
          cloudwatch_log_options = {
            enabled           = false
            log_group_arn     = ""
            log_output_format = "json"
          }
        }
      }
    ]
  }

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK - PEERING (ZRH-FRA)
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_frankfurt_peering" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/peering?ref=1.1.1"

  # all transit gateway peerings will be associated with the same transit gateway route table
  create_transit_gateway_peering_association              = true
  transit_gateway_peering_association_with_route_table_id = module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-hub"]

  # the transit gateway accepting a peering is called 'accepter'
  # accepter transit gateway can accept peerings with multiple transit gateways in different regions and/or accounts
  # transit gateway peers need to initialize the peering beforehand and are therefore called 'requester'
  transit_gateway_accept_peerings = [
    # {
    #   requester_transit_gateway_name          = ""
    #   requester_transit_gateway_id            = ""
    #   requester_transit_gateway_attachment_id = ""
    # }
    module.ntc_core_network_zurich_peering.transit_gateway_peering_info_for_accepter["tgw-core-frankfurt"]
  ]

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC CORE NETWORK - CUSTOM ROUTES
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_core_network_frankfurt_custom_routes" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/custom-routes?ref=1.1.1"

  # add custom routes for more flexibility and full control (e.g. firewall deployment)
  transit_gateway_custom_routes = [
    {
      # unique name to identify the route
      route_identifier = "route_prod_spoke_to_central_endpoints"
      # route table where custom route will be be added
      route_table_id = module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-prod"]
      # transit gateway attachment (Peering, VPC, Direct Connect, VPN) where traffic should be forwarded to
      attachment_id = module.ntc_vpc_central_endpoints.transit_gateway_vpc_attachement_id
      # set to true to drop specific traffic. cannot be combined with 'attachment_id'
      blackhole = false
      # what is the destination of the traffic that should be controlled by this route?
      # supported destination_type: 'cidr_block' (IPv4 or IPv6), 'prefix_list_id'
      destination_type = "cidr_block"
      destination      = "10.100.10.0/24"
    },
    {
      route_identifier = "blackhole_dev_spoke_to_central_endpoints"
      route_table_id   = module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-dev"]
      attachment_id    = ""
      blackhole        = true
      destination_type = "cidr_block"
      destination      = "10.100.10.0/24"
    },
    {
      route_identifier = "route_int_spoke_to_central_endpoints"
      route_table_id   = module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-int"]
      attachment_id    = module.ntc_vpc_central_endpoints.transit_gateway_vpc_attachement_id
      blackhole        = false
      destination_type = "cidr_block"
      destination      = "10.100.10.0/24"
    },
    {
      route_identifier = "dev_spoke_to_tgw_zurich"
      route_table_id   = module.ntc_core_network_frankfurt.transit_gateway_route_table_ids["tgw-core-rtb-spoke-dev"]
      attachment_id    = module.ntc_core_network_frankfurt_peering.transit_gateway_peering_attachment_id_by_peer_name["tgw-core-zurich"]
      blackhole        = false
      destination_type = "cidr_block"
      destination      = "10.200.0.0/16"
    }
  ]

  providers = {
    aws = aws.euc1
  }
}
