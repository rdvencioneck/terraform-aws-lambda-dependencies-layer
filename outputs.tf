output "layer_arn" {
  description = "Created lambda Layer ARN"
  value       = jsondecode(data.aws_lambda_invocation.nodejs_layer_builder.result)["LayerArn"]
}

output "layer_version_arn" {
  description = "Created lambda Layer ARN with Version"
  value       = jsondecode(data.aws_lambda_invocation.nodejs_layer_builder.result)["LayerVersionArn"]
}

output "layer_version" {
  description = "Created lambda Layer Version"
  value       = jsondecode(data.aws_lambda_invocation.nodejs_layer_builder.result)["Version"]
}