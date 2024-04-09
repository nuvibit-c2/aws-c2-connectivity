output "default_region" {
  description = "The default region name"
  value       = data.aws_region.default.name
}

output "account_id" {
  description = "The current account id"
  value       = data.aws_caller_identity.current.account_id
}

output "ntc_parameters" {
  description = "Map of all ntc parameters"
  value       = local.ntc_parameters
}

output "ntc_vpc_prod_stage" {
  description = "Outputs of prod stage VPC module"
  value       = module.ntc_vpc_prod_stage
}

output "ntc_core_network_frankfurt" {
  description = "Outputs of frankfurt core network module"
  value       = merge(module.ntc_core_network_frankfurt, { vpn_preshared_keys_by_connection_name : null })
}