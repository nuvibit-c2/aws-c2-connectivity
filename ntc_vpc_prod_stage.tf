# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC VPC - PROD STAGE
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_vpc_prod_stage" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-vpc?ref=1.2.1"

  # a prefix which will be added to all vpc resources
  prefix_name = "prod-stage"

  # subnets will be generated for each reserved AZ. Resources like NAT Gateway, VPC Endpoints and RAM sharing only for active AZs
  # WARNING: changing the reserved count can lead to subnets beeing redeployed
  availability_zones = {
    reserved = 3
    active   = 1
    # filter_zone_names = []
  }

  # define customer managed prefix lists e.g. for all on-premises ip ranges
  customer_managed_prefix_lists = [
    {
      name = "onprem-ipv4-ranges"
      entries = [
        {
          cidr        = "192.168.10.0/24"
          description = "Server Zone A"
        },
        {
          cidr        = "192.168.20.0/24"
          description = "Server Zone B"
        },
        {
          cidr        = "192.168.30.0/24"
          description = "Server Zone C"
        }
      ]
      # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "945766593056"]
      # ram_share_allow_external_principals = false
    }
  ]

  # define primary cidr block for the VPC
  vpc_ipv4_primary_cidr = "172.16.50.0/24"

  # define additional cidr blocks for the VPC
  vpc_ipv4_secondary_cidr_blocks = [
    {
      cidr_identifier = "cloudonly"
      cidr_block      = "100.64.108.0/22"
    }
  ]

  # (optional) use IPAM to get cidr blocks dynamically
  vpc_ipam_settings = {
    # cidrs will be dynamically requested from IPAM - this overwrites 'vpc_ipv4_primary_cidr'
    cidrs_requested_from_ipam = false
    # Terraform can allocate (reserve) cidrs (static or dynamic) in IPAM and assign to VPC
    cidrs_allocated_by_terraform     = false
    reservation_description          = "this cidr was allocated by terraform"
    ipv4_primary_pool_id             = module.ipam.nested_pools_ids["/toplevel/frankfurt"]
    ipv4_primary_pool_netmask_length = module.ipam.nested_pools_allocation_configs["/toplevel/frankfurt"].allocation_default_netmask_length
    ipv4_secondary_pools             = []
  }

  vpc_subnets = [
    {
      # (optional) for VPCs with secondary cidr blocks the 'vpc_cidr_identifier' is required. Primary cidr block is always 'primary'
      vpc_cidr_identifier = "primary"
      # unique identifier for subnet - renaming will cause subnet to be recreated
      subnet_identifier = "hybrid-private"
      # subnets can be of type 'private', 'public', 'firewall' or 'transit'
      subnet_type = "private"
      # setting netmask_length will dynamically calculate or allocate (with ipam) corresponding cidr ranges
      # when calculating cidrs the subnets will be sorted from largest to smallest to optimize cidr space
      # WARNING: changing the netmask_length can lead to subnets beeing redeployed
      netmask_length = 26
      # instead of dynamically calculating subnet cidrs based on netmask length a list of static cidrs can be provided
      static_cidrs = []
      # specific configuration for subnet type
      private_subnet_config = {
        default_route_to_public_nat_gateway = false
        default_route_to_transit_gateway    = true
      }
      # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "945766593056"]
      # ram_share_allow_external_principals = false
    },
    {
      # (optional) for VPCs with secondary cidr blocks the 'vpc_cidr_identifier' is required. Primary cidr block is always 'primary'
      vpc_cidr_identifier = "cloudonly"
      # unique identifier for subnet - renaming will cause subnet to be recreated
      subnet_identifier = "cloudonly-public"
      # subnets can be of type 'private', 'public', 'firewall' or 'transit'
      subnet_type = "public"
      # setting netmask_length will dynamically calculate or allocate (with ipam) corresponding cidr ranges
      # when calculating cidrs the subnets will be sorted from largest to smallest to optimize cidr space
      # WARNING: changing the netmask_length can lead to subnets beeing redeployed
      netmask_length = 27
      # instead of dynamically calculating subnet cidrs based on netmask length a list of static cidrs can be provided
      static_cidrs = []
      # specific configuration for subnet type
      public_subnet_config = {
        default_route_to_internet_gateway = true
        map_public_ip_on_launch           = true
        create_public_nat_gateway         = true
      }
      # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads/prod"]
      ]
      ram_share_allow_external_principals = false
    },
    {
      # (optional) for VPCs with secondary cidr blocks the 'vpc_cidr_identifier' is required. Primary cidr block is always 'primary'
      vpc_cidr_identifier = "cloudonly"
      # unique identifier for subnet - renaming will cause subnet to be recreated
      subnet_identifier = "cloudonly-private"
      # subnets can be of type 'private', 'public', 'firewall' or 'transit'
      subnet_type = "private"
      # setting netmask_length will dynamically calculate or allocate (with ipam) corresponding cidr ranges
      # when calculating cidrs the subnets will be sorted from largest to smallest to optimize cidr space
      # WARNING: changing the netmask_length can lead to subnets beeing redeployed
      netmask_length = 24
      # instead of dynamically calculating subnet cidrs based on netmask length a list of static cidrs can be provided
      static_cidrs = []
      # specific configuration for subnet type
      private_subnet_config = {
        default_route_to_public_nat_gateway = false
        default_route_to_transit_gateway    = true
      }
      # gateway endpoints can be used for 's3' and 'dynamodb' and can only be accessed from inside the VPC
      # to access 's3' endpoint from on-premises an interface endpoint is required. Combine both endpoint types for cost optimization
      gateway_endpoints = [
        {
          common_name = "s3"
          policy_json = null
          # by default gateway endpoint will be associated to current subnet
          associate_with_all_subnets = true
        },
        # {
        #   common_name = "dynamodb"
        # }
      ]
      # interface endpoints can be centralized and can also be accessed from on-premises
      # by default a security group will be created with https/443 ingress rule for the local VPC CIDR
      interface_endpoints = [
        # {
        #   common_name = "logs"
        #   policy_json = null
        #   # private dns should be disabled for centralized endpoints
        #   private_dns_enabled = true
        # },
        # {
        #   common_name = "ec2"
        #   policy_json = null
        #   # private dns should be disabled for centralized endpoints
        #   private_dns_enabled = true
        # }
      ]
      # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads/prod"]
      ]
      ram_share_allow_external_principals = false
    },
    {
      # (optional) for VPCs with secondary cidr blocks the 'vpc_cidr_identifier' is required. Primary cidr block is always 'primary'
      vpc_cidr_identifier = "cloudonly"
      # unique identifier for subnet - renaming will cause subnet to be recreated
      subnet_identifier = "cloudonly-firewall"
      # subnets can be of type 'private', 'public', 'firewall' or 'transit'
      subnet_type = "firewall"
      # setting netmask_length will dynamically calculate or allocate (with ipam) corresponding cidr ranges
      # when calculating cidrs the subnets will be sorted from largest to smallest to optimize cidr space
      # WARNING: changing the netmask_length can lead to subnets beeing redeployed
      netmask_length = 28
      # instead of dynamically calculating subnet cidrs based on netmask length a list of static cidrs can be provided
      static_cidrs = []
      # specific configuration for subnet type
      firewall_subnet_config = {
        default_route_to_public_nat_gateway = true
        default_route_to_internet_gateway   = false
        default_route_to_transit_gateway    = false
      }
      # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "945766593056"]
      # ram_share_allow_external_principals = false
    },
    {
      # (optional) for VPCs with secondary cidr blocks the 'vpc_cidr_identifier' is required. Primary cidr block is always 'primary'
      vpc_cidr_identifier = "cloudonly"
      # unique identifier for subnet - renaming will cause subnet to be recreated
      subnet_identifier = "cloudonly-transit"
      # subnets can be of type 'private', 'public', 'firewall' or 'transit'
      subnet_type = "transit"
      # setting netmask_length will dynamically calculate or allocate (with ipam) corresponding cidr ranges
      # when calculating cidrs the subnets will be sorted from largest to smallest to optimize cidr space
      # WARNING: changing the netmask_length can lead to subnets beeing redeployed
      netmask_length = 28
      # instead of dynamically calculating subnet cidrs based on netmask length a list of static cidrs can be provided
      static_cidrs = []
      # specific configuration for subnet type
      transit_subnet_config = {
        transit_gateway_create_attachment               = true
        transit_gateway_appliance_mode_support          = false
        transit_gateway_ipv6_support                    = false
        transit_gateway_dns_support                     = true
        transit_gateway_default_route_table_association = false
        transit_gateway_default_route_table_propagation = false
        transit_gateway_id                              = module.ntc_core_network.transit_gateway_id
        # vpc attachement can only be associated with a single transit gateway route table
        transit_gateway_association_with_route_table_id = module.ntc_core_network.transit_gateway_route_table_ids["tgw-core-rtb-spoke-prod"]
        # vpc attachement can propagate to multiple transit gateway route table for dynamic routing
        transit_gateway_propagation_to_route_table_ids = [
          module.ntc_core_network.transit_gateway_route_table_ids["tgw-core-rtb-hub"],
          module.ntc_core_network.transit_gateway_route_table_ids["tgw-core-rtb-spoke-prod"]
        ]
      }
      # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "945766593056"]
      # ram_share_allow_external_principals = false
    }
  ]

  # vpc flow logs can be delivered to s3, cloudwatch and kinesis-data-firehose.
  # it is possible to send flow logs from a single vpc to multiple targets in parallel e.g. s3 + cloudwatch
  vpc_flow_log_destinations = [
    {
      destination_type = "s3"
      destination_arn  = try(local.ntc_parameters["log-archive"]["log_bucket_arns"]["vpc_flow_logs"], "")
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
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC VPC - PROD STAGE - CUSTOM ROUTES
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_vpc_prod_stage_custom_routes" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-vpc//modules/custom-routes?ref=1.2.1"

  # add custom routes for more flexibility and full control (e.g. firewall deployment)
  custom_routes = [
    {
      # route table where custom route will be be added
      route_table_id = module.ntc_vpc_prod_stage.route_table_ids["cloudonly-private"][0]
      # what is the destination of the traffic that should be controlled by this route?
      # a single destination type is required and cannot combine multiple destination types
      destination = {
        cidr_block      = "10.100.10.0/24"
        ipv6_cidr_block = ""
        prefix_list_id  = ""
      }
      # what is the target of the traffic that should be controlled by this route?
      # a single target type is required and cannot combine multiple target types
      target = {
        carrier_gateway_id          = ""
        core_network_arn            = ""
        ipv6_egress_only_gateway_id = ""
        internet_gateway_id         = ""
        transit_gateway_id          = ""
        virtual_private_gateway_id  = ""
        vpc_peering_connection_id   = ""
        nat_gateway_id              = ""
        network_interface_id        = "eni-068b5ccd7f7b7cfd3"
        vpc_endpoint_id             = ""
      }
    },
    {
      route_table_id = module.ntc_vpc_prod_stage.route_table_ids["cloudonly-private"][1]
      destination = {
        cidr_block = "10.100.10.0/24"
      }
      target = {
        network_interface_id = "eni-0ca9af96faf51d443"
      }
    },
    {
      route_table_id = module.ntc_vpc_prod_stage.route_table_ids["cloudonly-private"][2]
      destination = {
        cidr_block = "10.100.10.0/24"
      }
      target = {
        network_interface_id = "eni-0e55b3e0b04ee1824"
      }
    }
  ]

  providers = {
    aws = aws.euc1
  }
}
