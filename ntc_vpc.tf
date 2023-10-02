# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # a prefix which will be added to all vpc resources
  vpc_prefix_name = "prod"

  # subnets will be generated for each reserved AZ. Resources like NAT Gateway, VPC Endpoints and RAM sharing only for active AZs
  # WARNING: changing the reserved count can lead to subnets beeing redeployed
  vpc_availability_zones = {
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
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "090258021222"]
    }
  ]

  # define primary cidr block for the VPC
  vpc_ipv4_primary_cidr = "100.64.108.0/22"
  # define additional cidr blocks for the VPC
  vpc_ipv4_secondary_cidr_blocks = [
    {
      cidr_identifier = "hybrid"
      cidr_block      = "172.120.50.0/24"
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
    # {
    #   subnet_identifier = "co-firewall"
    #   subnet_type        = "firewall"
    #   netmask_length     = 28
    #   firewall_subnet_config = {
    #     route_to_internet_gateway = false
    #     route_to_transit_gateway_destinations = []
    #   }
    # },
    {
      # (optional) for VPCs with secondary cidr blocks the 'vpc_cidr_identifier' is required. Primary cidr block is always 'primary'
      vpc_cidr_identifier = "primary"
      # unique identifier for subnet - renaming will cause subnet to be recreated
      subnet_identifier = "co-private"
      # subnets can be of type 'private', 'public' or 'transit'
      subnet_type = "private"
      # WARNING: changing the netmask_length can lead to subnets beeing redeployed
      netmask_length = 24
      # instead of dynamically calculating subnet cidrs based on netmask length a list of static cidrs can be provided
      static_cidrs = []
      # configure routing for subnet
      private_subnet_config = {
        default_route_to_public_nat_gateway = false
        # default_route_to_transit_gateway = false
        # route_to_network_firewall_destinations = ["0.0.0.0/0", "prefix_list_id"]
        # route_to_transit_gateway_destinations = ["10.0.0.0/8", "prefix_list_id"]
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
        {
          common_name = "logs"
          policy_json = null
          # private dns must be disabled for centralized endpoints
          private_dns_enabled = true
        },
        # {
        #   common_name = "ec2"
        # },
        # {
        #   common_name = "lambda"
        # }
      ]
      # (optional) share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "090258021222"]
    },
    {
      vpc_cidr_identifier = "primary"
      subnet_identifier   = "co-public"
      subnet_type         = "public"
      netmask_length      = 26
      public_subnet_config = {
        create_public_nat_gateway = false
        map_public_ip_on_launch   = true
        # route_to_network_firewall_destinations = ["0.0.0.0/0", "prefix_list_id"]
        # route_to_transit_gateway_destinations = ["10.0.0.0/8", "prefix_list_id"]
      }
      ram_share_principals = []
    },
    {
      vpc_cidr_identifier   = "primary"
      subnet_identifier     = "co-transit"
      subnet_type           = "transit"
      netmask_length        = 28
      transit_subnet_config = {}
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
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC VPC
# ---------------------------------------------------------------------------------------------------------------------
module "prod_stage_vpc" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-vpc?ref=beta"

  prefix_name                    = local.vpc_prefix_name
  availability_zones             = local.vpc_availability_zones
  customer_managed_prefix_lists  = local.customer_managed_prefix_lists
  vpc_ipv4_primary_cidr          = local.vpc_ipv4_primary_cidr
  vpc_ipv4_secondary_cidr_blocks = local.vpc_ipv4_secondary_cidr_blocks
  vpc_ipam_settings              = local.vpc_ipam_settings
  vpc_subnets                    = local.vpc_subnets
  vpc_flow_log_destinations      = local.vpc_flow_log_destinations

  providers = {
    aws = aws.euc1
  }
}
