
# move dnssec to root module
moved {
  from = module.ntc_route53_nuvibit_dev_dnssec.aws_kms_alias.ntc_dnssec["ksk-1"]
  to   = module.ntc_route53_nuvibit_dev.module.dnssec[0].aws_kms_alias.ntc_dnssec["ksk-1"]
}

moved {
  from = module.ntc_route53_nuvibit_dev_dnssec.aws_kms_key.ntc_dnssec["ksk-1"]
  to   = module.ntc_route53_nuvibit_dev.module.dnssec[0].aws_kms_key.ntc_dnssec["ksk-1"]
}

moved {
  from = module.ntc_route53_nuvibit_dev_dnssec.aws_route53_hosted_zone_dnssec.ntc_dnssec["ksk-1"]
  to   = module.ntc_route53_nuvibit_dev.module.dnssec[0].aws_route53_hosted_zone_dnssec.ntc_dnssec["ksk-1"]
}

moved {
  from = module.ntc_route53_nuvibit_dev_dnssec.aws_route53_key_signing_key.ntc_dnssec["ksk-1"]
  to   = module.ntc_route53_nuvibit_dev.module.dnssec[0].aws_route53_key_signing_key.ntc_dnssec["ksk-1"]
}

# move query logs to root module
moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_route53_query_log.ntc_query_log
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_route53_query_log.ntc_query_log
}

moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_kms_key.ntc_query_log_encryption[0]
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_kms_key.ntc_query_log_encryption[0]
}

moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_kms_alias.ntc_query_log_encryption[0]
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_kms_alias.ntc_query_log_encryption[0]
}

moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_cloudwatch_log_resource_policy.ntc_query_log
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_cloudwatch_log_resource_policy.ntc_query_log
}

moved {
  from = module.ntc_route53_nuvibit_dev_query_logging.aws_cloudwatch_log_group.ntc_query_log
  to   = module.ntc_route53_nuvibit_dev.module.query_logs[0].aws_cloudwatch_log_group.ntc_query_log
}
