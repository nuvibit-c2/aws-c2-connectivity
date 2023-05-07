# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # a prefix which will be added to all vpc resources
  vpc_prefix_name = "prod"

  # subnets will be generated for each availability zone
  vpc_availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

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
    {
      subnet_prefix_name = "private"
      subnet_type        = "private"
      netmask_length     = 24
      private_subnet_config = {
        # route_to_public_nat_gateway = true
      }
      # share subnet with Organizations, OUs or Account IDs
      # ram_share_principals = ["945766593056"]
    },
    {
      subnet_prefix_name = "public"
      subnet_type        = "public"
      netmask_length     = 26
      public_subnet_config = {
        # create_public_nat_gateway_in = "all_azs"
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
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC IPAM
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

  providers = {
    aws = aws.euc1
  }
}