data "aws_route53_zone" "this" {
  zone_id = var.hosted_zone
}

data "aws_s3_bucket" "this" {
  provider = aws.usw2
  for_each = toset(var.object_storage_origins)
  bucket   = each.value
}

#   s3_oac = { # with origin access control settings (recommended)
#     domain_name           = module.s3_one.s3_bucket_bucket_regional_domain_name
#     origin_access_control = "s3_oac" # key in `origin_access_control`
#     #      origin_access_control_id = "E345SXM82MIOSU" # external OAС resource
#   }

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

  create_origin_access_control = true
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
  default_cache_behavior = var.default_cache_behavior

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

#############################################
# Using packaged function from Lambda module
#############################################

locals {
  package_url = "https://raw.githubusercontent.com/terraform-aws-modules/terraform-aws-lambda/master/examples/fixtures/python3.8-zip/existing_package.zip"
  downloaded  = "downloaded_package_${md5(local.package_url)}.zip"
}

# resource "null_resource" "download_package" {
#   triggers = {
#     downloaded = local.downloaded
#   }

#   provisioner "local-exec" {
#     command = "curl -L -o ${local.downloaded} ${local.package_url}"
#   }
# }

# module "lambda_function" {
#   source  = "terraform-aws-modules/lambda/aws"
#   version = "~> 4.0"

#   function_name = "${random_pet.this.id}-lambda"
#   description   = "My awesome lambda function"
#   handler       = "index.lambda_handler"
#   runtime       = "python3.8"

#   publish        = true
#   lambda_at_edge = true

#   create_package         = false
#   local_existing_package = local.downloaded

#   # @todo: Missing CloudFront as allowed_triggers?

#   #    allowed_triggers = {
#   #      AllowExecutionFromAPIGateway = {
#   #        service = "apigateway"
#   #        arn     = module.api_gateway.apigatewayv2_api_execution_arn
#   #      }
#   #    }
# }

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


# ########
# # Extra
# ########

# resource "random_pet" "this" {
#   length = 2
# }

# resource "aws_cloudfront_function" "example" {
#   name    = "example-${random_pet.this.id}"
#   runtime = "cloudfront-js-1.0"
#   code    = file("${path.module}/example-function.js")
# }
