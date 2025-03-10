# CloudFront Distribution (Now Using NLB as the Origin)
resource "aws_cloudfront_distribution" "cloudfront" {
  origin {
    domain_name = aws_lb.nlb.dns_name  
    origin_id   = "nlb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" 
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "nlb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "CloudFront-NLB"
  }
}


# Utilize this script for Origin Access Control

# resource "aws_cloudfront_distribution" "cloudfront" {
#   origin {
#     domain_name = aws_lb.nlb.dns_name
#     origin_id   = "nlb-origin"

#     custom_origin_config {
#       http_port              = 80
#       https_port             = 443
#       origin_protocol_policy = "match-viewer"  # Adjusted to match the viewer protocol
#       origin_ssl_protocols   = ["TLSv1.2"]
#     }
#   }

#   origin {
#     domain_name = "${aws_s3_bucket.my_bucket.bucket_regional_domain_name}"
#     origin_id   = "s3-origin"

#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
#     }
#   }

#   enabled             = true
#   default_root_object = "index.html"

#   default_cache_behavior {
#     target_origin_id       = "nlb-origin"
#     viewer_protocol_policy = "redirect-to-https"
#     allowed_methods        = ["GET", "HEAD", "OPTIONS"]
#     cached_methods         = ["GET", "HEAD"]
#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#     }
#     min_ttl     = 0
#     default_ttl = 3600
#     max_ttl     = 86400
#   }

#   ordered_cache_behavior {
#     path_pattern           = "/path/to/s3/*"  # Specify the path pattern that applies to the S3 bucket
#     target_origin_id       = "s3-origin"
#     viewer_protocol_policy = "redirect-to-https"
#     allowed_methods        = ["GET", "HEAD", "OPTIONS"]
#     cached_methods         = ["GET", "HEAD"]
#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#     }
#     min_ttl     = 0
#     default_ttl = 3600
#     max_ttl     = 86400
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   tags = {
#     Name = "CloudFront-NLB-S3"
#   }
# }

# # S3 Bucket
# resource "aws_s3_bucket" "my_bucket" {
#   bucket = "my-secure-bucket"
#   acl    = "private"
# }

# # CloudFront Origin Access Identity for S3 Bucket
# resource "aws_cloudfront_origin_access_identity" "oai" {
#   comment = "OAI for accessing S3 bucket securely"
# }
