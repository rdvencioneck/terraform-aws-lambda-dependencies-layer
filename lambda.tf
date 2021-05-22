data "archive_file" "lambda_dependencies_layer_builder" {
  type        = "zip"
  source {
    content  = file(var.dependencies_file)
    filename = basename(var.dependencies_file)
  }

  source {
    content  = length(regexall("python", var.runtime)) > 0 ? file("${path.module}/src/python_dependencies_layer_builder.py") : file("${path.module}/src/nodeJSDependenciesLayerBuilder.js")
    filename = "builder.%{ if length(regexall("python", var.runtime)) > 0 }py%{ else }js%{ endif }"
  } 
  output_path = "dependencies_layer_builder.zip"
}

module "lambda_dependencies_layer_builder" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.layer_name}_layer_builder"
  description   = "Function for building Lambda dependencies and saving in S3"
  handler       = "builder.handler"
  runtime       = var.runtime
  publish       = true
  memory_size   = var.layer_builder_lambda_memory
  timeout       = 900

  create_package         = false
  local_existing_package = data.archive_file.lambda_dependencies_layer_builder.output_path

  attach_policy_statements = true
  policy_statements = {
    layer_builder_permissions = {
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "s3:*",
        "lambda:*",
      ]
      resources = ["*"]
      effect    = "Allow"
    }
  }

  tags = var.tags
}