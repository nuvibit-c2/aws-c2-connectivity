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
  }

  # if IPAM should NOT be used then 'vpc_ipv4_cidr' will be used for VPC
  vpc_ipv4_cidr = "100.64.108.0/22"

  # if IPAM should be used then a dynamic IPAM CIDR will be used for VPC
  vpc_use_ipam = false

  # allocation can be managed by Terraform instead of dynamically by VPC
  # IPAM will not import the VPC and no IP addresses will be scanned
  vpc_ipam_reserve_cidr        = false
  vpc_ipam_reserve_description = "reservation for terraform managed vpc"
  # get pool id from output of ipam module referenced by pool_path
  vpc_ipv4_ipam_pool_id        = module.ipam.nested_pools_ids["/toplevel/frankfurt"]
  vpc_ipv4_ipam_netmask_length = module.ipam.nested_pools_allocation_configs["/toplevel/frankfurt"].allocation_default_netmask_length

  vpc_subnets = [
    # {
    #   subnet_prefix_name = "firewall"
    #   subnet_type        = "firewall"
    #   netmask_length     = 28
    #   firewall_subnet_config = {
    #     route_to_internet_gateway = false
    #     route_to_transit_gateway_destinations = []
    #   }
    # },
    {
      subnet_prefix_name = "private"
      subnet_type        = "private"
      # WARNING: changing the netmask_length can lead to subnets beeing redeployed
      netmask_length = 24
      private_subnet_config = {
        route_to_public_nat_gateway = false
        # route_to_network_firewall_destinations = ["0.0.0.0/0", "prefix_list_id"]
        # route_to_transit_gateway_destinations = ["10.0.0.0/8", "prefix_list_id"]
      }
      # interface endpoints should only be added to the private subnet
      interface_endpoints = {
        service_names = [
          "ec2",
          # "ec2messages",
          # "events",
          # "lambda",
          # "logs",
          # "rds",
          # "rds-data"
          # "sns",
          # "sqs"
        ]
        private_dns_enabled = true
        # if no security group is created the default vpc security group will be attached
        create_security_group = true
        # if no cidr block is provided the vpc cidr range will be added
        allowed_cidr_blocks = []
        inbound_ports       = ["443"]
      }
      # share subnet with Organizations, OUs or Accounts - requires RAM to be enabled for Organizations
      # ram_share_principals = ["o-m29e8d9awz", "ou-6gf5-6ltp3mjf", "090258021222"]
    },
    {
      subnet_prefix_name = "public"
      subnet_type        = "public"
      netmask_length     = 26
      public_subnet_config = {
        create_public_nat_gateway = false
        map_public_ip_on_launch   = true
        # route_to_network_firewall_destinations = ["0.0.0.0/0", "prefix_list_id"]
        # route_to_transit_gateway_destinations = ["10.0.0.0/8", "prefix_list_id"]
      }
      ram_share_principals = []
    },
    {
      subnet_prefix_name    = "transit"
      subnet_type           = "transit"
      netmask_length        = 28
      transit_subnet_config = {}
      ram_share_principals  = []
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

  prefix_name                  = local.vpc_prefix_name
  availability_zones           = local.vpc_availability_zones
  vpc_ipv4_cidr                = local.vpc_use_ipam == false ? local.vpc_ipv4_cidr : null
  vpc_use_ipam_cidr            = local.vpc_use_ipam
  vpc_ipam_reserve_cidr        = local.vpc_ipam_reserve_cidr
  vpc_ipam_reserve_description = local.vpc_ipam_reserve_description
  vpc_ipv4_ipam_pool_id        = local.vpc_ipv4_ipam_pool_id
  vpc_ipv4_ipam_netmask_length = local.vpc_ipv4_ipam_netmask_length
  vpc_subnets                  = local.vpc_subnets
  vpc_flow_log_destinations    = local.vpc_flow_log_destinations

  providers = {
    aws = aws.euc1
  }
}