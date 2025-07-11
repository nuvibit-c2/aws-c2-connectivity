# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC IPAM
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_ipam" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-ipam?ref=1.0.2"

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
        "100.72.0.0/14"
      ]
    },
    {
      pool_path   = "/toplevel/frankfurt/prod"
      pool_name   = "Prod Pool"
      pool_region = "eu-central-1"
      description = "staging pool"
      cidrs       = cidrsubnets("100.64.0.0/14", 2, 2, 2, 2)
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
      pool_name   = "Dev Pool"
      pool_region = "eu-central-1"
      description = "staging pool"
      cidrs       = cidrsubnets("100.68.0.0/14", 2, 2, 2, 2)
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
      pool_path   = "/toplevel/ireland"
      pool_name   = "Europe (Ireland) Pool"
      pool_region = "eu-west-1"
      description = "regional pool"
      cidrs = [
        "100.124.0.0/14",
        "100.120.0.0/14",
        "100.116.0.0/14"
      ]
    }
  ]

  providers = {
    aws = aws.euc1
  }
}
