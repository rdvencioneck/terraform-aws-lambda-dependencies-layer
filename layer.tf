resource "aws_lambda_layer_version" "this" {

  layer_name   = var.layer_name
  description  = var.layer_description
  license_info = var.license_info

  compatible_runtimes = length(var.compatible_runtimes) > 0 ? var.compatible_runtimes : [var.runtime]

  s3_bucket         = var.s3_bucket_name
  s3_key            = "${var.s3_key_prefix}${var.layer_name}.zip"

  depends_on = [
    data.aws_lambda_invocation.nodejs_layer_builder,
  ]
}