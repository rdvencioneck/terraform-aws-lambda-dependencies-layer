output "layer_arn" {
  description = "Created lambda Layer ARN without version"
  value       = aws_lambda_layer_version.this.layer_arn
}

output "layer_version_arn" {
  description = "Created lambda Layer ARN with Version"
  value       = aws_lambda_layer_version.this.arn
}

output "layer_version" {
  description = "Created lambda Layer Version"
  value       = aws_lambda_layer_version.this.version
}