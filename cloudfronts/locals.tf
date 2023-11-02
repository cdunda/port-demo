
locals {
  aliases = [for alias in var.aliases : "${alias}.${data.aws_route53_zone.this.name}"]

  origin_defaults = {
    domain_name         = "example-bucket.s3.amazonaws.com"
    origin_path         = "" # Empty as it's optional
    custom_header       = [] # Empty list as we usually don't need custom headers for S3
    origin_shield       = {}
    connection_attempts = 3
    connection_timeout  = 10
  }

  custom_origin_defaults = {
    custom_origin_config = {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "match-viewer"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  s3_origins = {
    for s3bucket in var.object_storage_origins : s3bucket => merge(local.origin_defaults, {
      domain_name              = data.aws_s3_bucket.this[s3bucket].bucket_regional_domain_name
      origin_access_control_id = "E3SF69DXKY5VS5"
    })
  }

  custom_origins = {
    for custom_origin_id, origin_config in var.custom_origins : custom_origin_id =>
    merge(
      local.origin_defaults,
      local.custom_origin_defaults,
      origin_config
    )
  }

  origins = merge(local.custom_origins, local.s3_origins)


  cache_behavior_defaults = {
    target_origin_id = "example-origin-id"

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000

    compress                   = true
    smooth_streaming           = false
    cache_policy_id            = data.aws_cloudfront_cache_policy.this.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.this.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.this.id


    lambda_function_associations = [] # Empty list as it's optional

    field_level_encryption_id = "" # Empty as it's optional
    use_forwarded_values      = false
  }

  # ensure if it's an s3 origin, it uses the s3 origin request policy
  ordered_cache_behaviors = [
    for cache_behavior in var.ordered_cache_behaviors : merge(
      local.cache_behavior_defaults,
      cache_behavior,
      {
        origin_request_policy_id = contains(var.object_storage_origins, cache_behavior.target_origin_id) ? data.aws_cloudfront_origin_request_policy.s3.id : local.cache_behavior_defaults.origin_request_policy_id
      }
    )
  ]

  # ensure if it's an s3 origin, it uses the s3 origin request policy
  default_cache_behavior = merge(
    local.cache_behavior_defaults,
    var.default_cache_behavior,
    {
      origin_request_policy_id = contains(var.object_storage_origins, var.default_cache_behavior.target_origin_id) ? data.aws_cloudfront_origin_request_policy.s3.id : local.cache_behavior_defaults.origin_request_policy_id
    }
  )

}
