output "dynamodb_table_name" {
  value = aws_dynamodb_table.visitor_count_table.name
}

#--------------------------------lambda
#--------------------------------lambda


#--------------------------------api
output "api_url" {
  value = aws_apigatewayv2_api.visitor_api.api_endpoint
}
#--------------------------------api

#--------------------------------s3
# output "s3_website_url" {
#   value = aws_s3_bucket_website_configuration.website.website_endpoint
# }
output "s3_url" {
  value = aws_s3_bucket.frontend_bucket.bucket_domain_name
}
#--------------------------------s3

#--------------------------------cdn
output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
#--------------------------------cdn