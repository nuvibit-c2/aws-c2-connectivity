locals {
  ntc_parameters_bucket_name = "aws-c2-ntc-parameters"
  ntc_parameters_writer_node = "connectivity"

  # parameters that are managed by core connectivity account
  ntc_parameters_to_write = {
    "customer_managed_prefix_lists" = module.ntc_vpc_prod_stage.customer_managed_prefix_lists
    "transit_gateway_zurich"        = module.ntc_core_network_zurich.transit_gateway_id
    "transit_gateway_frankfurt"     = module.ntc_core_network_frankfurt.transit_gateway_id
    "ipam_pools_ids"                = module.ntc_ipam.nested_pools_ids
    "baseline_assume_role_arn"      = aws_iam_role.ntc_baseline.arn
  }

  # by default existing node parameters will be merged with new parameters to avoid deleting parameters
  ntc_replace_parameters = true

  # map of parameters merged from all parameter nodes
  ntc_parameters = module.ntc_parameters_reader.all_parameters
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_reader" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader?ref=1.1.2"

  bucket_name = local.ntc_parameters_bucket_name

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_writer" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer?ref=1.1.2"

  bucket_name        = local.ntc_parameters_bucket_name
  parameter_node     = local.ntc_parameters_writer_node
  node_parameters    = local.ntc_parameters_to_write
  replace_parameters = local.ntc_replace_parameters

  providers = {
    aws = aws.euc1
  }
}
