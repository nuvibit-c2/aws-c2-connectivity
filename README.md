<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- terraform (>= 1.3.0)

- aws (~> 5.33)

## Providers

The following providers are used by this module:

- aws (~> 5.33)

## Modules

The following Modules are called:

### ntc\_core\_network\_frankfurt

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network

Version: 1.2.1

### ntc\_core\_network\_frankfurt\_custom\_routes

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/custom-routes

Version: 1.2.1

### ntc\_core\_network\_frankfurt\_peering

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/peering

Version: 1.2.1

### ntc\_core\_network\_zurich

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network

Version: 1.2.1

### ntc\_core\_network\_zurich\_custom\_routes

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/custom-routes

Version: 1.2.1

### ntc\_core\_network\_zurich\_peering

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-core-network//modules/peering

Version: 1.2.1

### ntc\_ipam

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-ipam

Version: 1.0.2

### ntc\_parameters\_reader

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader

Version: 1.1.4

### ntc\_parameters\_writer

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer

Version: 1.1.4

### ntc\_route53\_central\_endpoints

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53

Version: 1.3.0

### ntc\_route53\_mydomain\_internal

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53

Version: 1.3.0

### ntc\_route53\_nuvibit\_dev

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53

Version: 1.3.0

### ntc\_route53\_nuvibit\_dev\_dnssec

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/dnssec

Version: 1.3.0

### ntc\_route53\_nuvibit\_dev\_query\_logging

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/query-logs

Version: 1.3.0

### ntc\_route53\_resolver

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-route53//modules/resolver

Version: 1.3.0

### ntc\_vpc\_central\_endpoints

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-vpc

Version: 1.6.0

### ntc\_vpc\_prod\_stage

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-vpc

Version: 1.6.0

### ntc\_vpc\_prod\_stage\_custom\_routes

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-vpc//modules/custom-routes

Version: 1.6.0

## Resources

The following resources are used by this module:

- [aws_iam_role.ntc_baseline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role_policy.ntc_baseline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) (resource)
- [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) (data source)
- [aws_iam_policy_document.ntc_baseline_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) (data source)
- [aws_iam_policy_document.ntc_baseline_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) (data source)
- [aws_region.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data source)

## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### account\_id

Description: The current account id

### default\_region

Description: The default region name

### ntc\_core\_network\_frankfurt

Description: Outputs of frankfurt core network module

### ntc\_parameters

Description: Map of all ntc parameters

### ntc\_vpc\_prod\_stage

Description: Outputs of prod stage VPC module
<!-- END_TF_DOCS -->