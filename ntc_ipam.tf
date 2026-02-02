# ---------------------------------------------------------------------------------------------------------------------
# § LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  customer_managed_prefix_lists = [
    {
      name    = "cidrs-aws-global"
      entries = [for cidr in module.ntc_ipam.nested_pools_cidrs["/toplevel"] : { cidr = cidr }]
      # share customer_managed_prefix_lists with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads"],
      ]
    },
    {
      name    = "cidrs-aws-frankfurt"
      entries = [for cidr in module.ntc_ipam.nested_pools_cidrs["/toplevel/frankfurt"] : { cidr = cidr }]
      # share customer_managed_prefix_lists with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads"],
      ]
    },
    {
      name    = "cidrs-aws-zurich"
      entries = [for cidr in module.ntc_ipam.nested_pools_cidrs["/toplevel/zurich"] : { cidr = cidr }]
      # share customer_managed_prefix_lists with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads"],
      ]
    },
    {
      name    = "cidrs-onprem"
      entries = [for cidr in ["10.0.0.0/8", "192.168.0.0/16"] : { cidr = cidr }]
      # share customer_managed_prefix_lists with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads"],
      ]
    },
    {
      name    = "cidrs-onprem-dns"
      entries = [for cidr in ["10.8.8.8/32", "10.8.4.4/32"] : { cidr = cidr }]
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC IPAM
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_ipam" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-ipam?ref=2.0.0"

  region      = "eu-central-1"
  description = "Organizational IPAM"

  nested_pools = [
    {
      pool_path   = "/toplevel"
      pool_name   = "Global (CGNAT) Pool"
      description = "top-level pool"
      cidrs       = ["100.64.0.0/10"]
    },
    {
      pool_path   = "/toplevel/frankfurt"
      pool_name   = "Europe (Frankfurt) Pool"
      pool_region = "eu-central-1"
      description = "regional pool"
      cidrs = [
        "100.64.0.0/14",
        "100.68.0.0/14",
        "100.72.0.0/14",
        "100.76.0.0/14",
      ]
    },
    {
      pool_path   = "/toplevel/frankfurt/prod"
      pool_name   = "Frankfurt Workloads Prod"
      pool_region = "eu-central-1"
      description = "prod workloads"
      cidrs       = ["100.64.0.0/14"]
      # share IPAM with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads/prod"]
      ]
      allocation_default_netmask_length = 22
      allocation_max_netmask_length     = 22
      allocation_min_netmask_length     = 22
      allocation_resource_tags          = {}
    },
    {
      pool_path   = "/toplevel/frankfurt/dev"
      pool_name   = "Frankfurt Workloads Dev"
      pool_region = "eu-central-1"
      description = "dev workloads"
      cidrs       = ["100.68.0.0/14"]
      # share IPAM with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads/dev"]
      ]
      allocation_default_netmask_length = 22
      allocation_max_netmask_length     = 22
      allocation_min_netmask_length     = 22
      allocation_resource_tags          = {}
    },
    {
      pool_path   = "/toplevel/frankfurt/test"
      pool_name   = "Frankfurt Workloads test"
      pool_region = "eu-central-1"
      description = "test workloads"
      cidrs       = ["100.72.0.0/14"]
      # share IPAM with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads/test"]
      ]
      allocation_default_netmask_length = 22
      allocation_max_netmask_length     = 22
      allocation_min_netmask_length     = 22
      allocation_resource_tags          = {}
    },
    {
      pool_path                         = "/toplevel/frankfurt/core-network"
      pool_name                         = "Frankfurt Core Network"
      pool_region                       = "eu-central-1"
      description                       = "core network"
      cidrs                             = ["100.76.0.0/14"]
      allocation_default_netmask_length = 22
      allocation_max_netmask_length     = 22
      allocation_min_netmask_length     = 22
      allocation_resource_tags          = {}
    },
    {
      pool_path   = "/toplevel/zurich"
      pool_name   = "Europe (Zurich) Pool"
      pool_region = "eu-central-2"
      description = "regional pool"
      cidrs = [
        "100.112.0.0/14",
        "100.116.0.0/14",
        "100.120.0.0/14",
        "100.124.0.0/14",
      ]
    },
    {
      pool_path   = "/toplevel/zurich/prod"
      pool_name   = "Zurich Workloads Prod"
      pool_region = "eu-central-2"
      description = "prod workloads"
      cidrs       = ["100.112.0.0/14"]
      # share IPAM with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads/prod"]
      ]
      allocation_default_netmask_length = 22
      allocation_max_netmask_length     = 22
      allocation_min_netmask_length     = 22
      allocation_resource_tags          = {}
    },
    {
      pool_path   = "/toplevel/zurich/dev"
      pool_name   = "Zurich Workloads Dev"
      pool_region = "eu-central-2"
      description = "dev workloads"
      cidrs       = ["100.116.0.0/14"]
      # share IPAM with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads/dev"]
      ]
      allocation_default_netmask_length = 22
      allocation_max_netmask_length     = 22
      allocation_min_netmask_length     = 22
      allocation_resource_tags          = {}
    },
    {
      pool_path   = "/toplevel/zurich/test"
      pool_name   = "Zurich Workloads Test"
      pool_region = "eu-central-2"
      description = "test workloads"
      cidrs       = ["100.120.0.0/14"]
      # share IPAM with Organizations, OUs or Accounts
      ram_share_principals = [
        local.ntc_parameters["mgmt-organizations"]["ou_ids"]["/root/workloads/test"]
      ]
      allocation_default_netmask_length = 22
      allocation_max_netmask_length     = 22
      allocation_min_netmask_length     = 22
      allocation_resource_tags          = {}
    },
    {
      pool_path                         = "/toplevel/zurich/core-network"
      pool_name                         = "Zurich Core Network"
      pool_region                       = "eu-central-2"
      description                       = "core network"
      cidrs                             = ["100.128.0.0/14"]
      allocation_default_netmask_length = 22
      allocation_max_netmask_length     = 22
      allocation_min_netmask_length     = 22
      allocation_resource_tags          = {}
    },
  ]
}
