data "aws_route53_zone" "this" {
  zone_id = var.hosted_zone
}

data "aws_s3_bucket" "this" {
  provider = aws.usw2
  for_each = toset(var.object_storage_origins)
  bucket   = each.value
}

data "aws_cloudfront_origin_request_policy" "s3" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_origin_request_policy" "this" {
  name = "Managed-${var.origin_request_headers}"
}

data "aws_cloudfront_response_headers_policy" "this" {
  name = "Managed-${var.cors_response_headers}"
}

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-${var.cache_policy}"
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.2.1"

  aliases = local.aliases

  comment             = var.name
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  # When you enable additional metrics for a distribution, CloudFront sends up to 8 metrics to CloudWatch in the US East (N. Virginia) Region.
  # This rate is charged only once per month, per metric (up to 8 metrics per distribution).
  create_monitoring_subscription = true

  create_origin_access_control = false
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  # logging_config = {
  #   bucket = module.log_bucket.s3_bucket_bucket_domain_name
  #   prefix = "cloudfront"
  # }

  origin = local.origins

  # put this into local and merge with users default_cache_behavior
  default_cache_behavior = local.default_cache_behavior

  ordered_cache_behavior = local.ordered_cache_behaviors


  viewer_certificate = {
    acm_certificate_arn = var.ssl_cert
    ssl_support_method  = "sni-only"
  }

  custom_error_response = [{
    error_code         = 404
    response_code      = 404
    response_page_path = "/errors/404.html"
    }, {
    error_code         = 403
    response_code      = 403
    response_page_path = "/errors/403.html"
  }]

  geo_restriction = {
    restriction_type = "whitelist"
    locations        = ["NO", "UA", "US", "GB"]
  }

}

##########
# Route53
##########

module "records" {
  for_each = toset(var.aliases)
  source   = "terraform-aws-modules/route53/aws//modules/records"
  version  = "~> 2.0"

  zone_id = data.aws_route53_zone.this.zone_id

  records = [
    {
      name = each.value
      type = "A"
      alias = {
        name    = module.cloudfront.cloudfront_distribution_domain_name
        zone_id = module.cloudfront.cloudfront_distribution_hosted_zone_id
      }
    },
  ]
}
