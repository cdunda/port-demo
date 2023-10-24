variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "name" {
  description = "CloudFront distribution name"
  type        = string
}

variable "object_storage_origins" {
  description = "A list of S3 bucket for object storage origins"
  type        = list(string)
}

variable "hosted_zone" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "aliases" {
  description = "CloudFront aliases"
  type        = list(string)
}

variable "custom_origins" {
  description = "A map of origins for CloudFront distribution"
  type        = map(any)
}

variable "cors_response_headers" {
  description = "The cors response headers policy"
  type        = string
}

variable "origin_request_headers" {
  description = "The origin request headers policy"
  type        = string
}

variable "cache_policy" {
  description = "The cache policy"
  type        = string
}

variable "ssl_cert" {
  description = "The ARN of the SSL certificate"
  type        = string
}

variable "default_cache_behavior" {
  description = "The default cache behavior"
  type        = any
}

variable "ordered_cache_behaviors" {
  description = "The ordered cache behaviors"
  type        = list(any)
}

variable "cloud_provider" {
  description = "The cloud provider"
  type        = string
}
