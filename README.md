<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.33 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.33 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ntc_core_network_frankfurt"></a> [ntc\_core\_network\_frankfurt](#module\_ntc\_core\_network\_frankfurt) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network | 1.1.0 |
| <a name="module_ntc_core_network_frankfurt_custom_routes"></a> [ntc\_core\_network\_frankfurt\_custom\_routes](#module\_ntc\_core\_network\_frankfurt\_custom\_routes) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/custom-routes | 1.1.0 |
| <a name="module_ntc_core_network_frankfurt_peering"></a> [ntc\_core\_network\_frankfurt\_peering](#module\_ntc\_core\_network\_frankfurt\_peering) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/peering | 1.1.0 |
| <a name="module_ntc_core_network_zurich"></a> [ntc\_core\_network\_zurich](#module\_ntc\_core\_network\_zurich) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network | 1.1.0 |
| <a name="module_ntc_core_network_zurich_custom_routes"></a> [ntc\_core\_network\_zurich\_custom\_routes](#module\_ntc\_core\_network\_zurich\_custom\_routes) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/custom-routes | 1.1.0 |
| <a name="module_ntc_core_network_zurich_peering"></a> [ntc\_core\_network\_zurich\_peering](#module\_ntc\_core\_network\_zurich\_peering) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/peering | 1.1.0 |
| <a name="module_ntc_ipam"></a> [ntc\_ipam](#module\_ntc\_ipam) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-ipam | 1.0.2 |
| <a name="module_ntc_parameters_reader"></a> [ntc\_parameters\_reader](#module\_ntc\_parameters\_reader) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader | 1.1.2 |
| <a name="module_ntc_parameters_writer"></a> [ntc\_parameters\_writer](#module\_ntc\_parameters\_writer) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer | 1.1.2 |
| <a name="module_ntc_route53_central_endpoints"></a> [ntc\_route53\_central\_endpoints](#module\_ntc\_route53\_central\_endpoints) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53 | 1.1.2 |
| <a name="module_ntc_route53_mydomain_internal"></a> [ntc\_route53\_mydomain\_internal](#module\_ntc\_route53\_mydomain\_internal) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53 | 1.1.2 |
| <a name="module_ntc_route53_nuvibit_dev"></a> [ntc\_route53\_nuvibit\_dev](#module\_ntc\_route53\_nuvibit\_dev) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53 | 1.1.2 |
| <a name="module_ntc_route53_nuvibit_dev_dnssec"></a> [ntc\_route53\_nuvibit\_dev\_dnssec](#module\_ntc\_route53\_nuvibit\_dev\_dnssec) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/dnssec | 1.1.2 |
| <a name="module_ntc_route53_nuvibit_dev_query_logging"></a> [ntc\_route53\_nuvibit\_dev\_query\_logging](#module\_ntc\_route53\_nuvibit\_dev\_query\_logging) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/query-logs | 1.1.2 |
| <a name="module_ntc_route53_resolver"></a> [ntc\_route53\_resolver](#module\_ntc\_route53\_resolver) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/resolver | 1.1.2 |
| <a name="module_ntc_vpc_central_endpoints"></a> [ntc\_vpc\_central\_endpoints](#module\_ntc\_vpc\_central\_endpoints) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-vpc | 1.4.0 |
| <a name="module_ntc_vpc_prod_stage"></a> [ntc\_vpc\_prod\_stage](#module\_ntc\_vpc\_prod\_stage) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-vpc | 1.4.0 |
| <a name="module_ntc_vpc_prod_stage_custom_routes"></a> [ntc\_vpc\_prod\_stage\_custom\_routes](#module\_ntc\_vpc\_prod\_stage\_custom\_routes) | github.com/nuvibit-terraform-collection/terraform-aws-ntc-vpc//modules/custom-routes | 1.4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The current account id |
| <a name="output_default_region"></a> [default\_region](#output\_default\_region) | The default region name |
| <a name="output_ntc_core_network_frankfurt"></a> [ntc\_core\_network\_frankfurt](#output\_ntc\_core\_network\_frankfurt) | Outputs of frankfurt core network module |
| <a name="output_ntc_parameters"></a> [ntc\_parameters](#output\_ntc\_parameters) | Map of all ntc parameters |
| <a name="output_ntc_vpc_prod_stage"></a> [ntc\_vpc\_prod\_stage](#output\_ntc\_vpc\_prod\_stage) | Outputs of prod stage VPC module |
<!-- END_TF_DOCS -->