data "archive_file" "nodejs_lambda_dependencies_layer_builder" {
  type        = "zip"
  source {
    content  = file(var.dependencies_file)
    filename = "package.json"
  }

  source {
    content  = file("${path.module}/src/nodeJSDependenciesLayerBuilder.js")
    filename = "nodeJSDependenciesLayerBuilder.js"
  } 
  output_path = "nodejs_dependencies_layer_builder.zip"
}

module "nodejs_lambda_dependencies_layer_builder" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "nodejs_lambda_dependencies_layer_builder"
  description   = "Function for building NodeJS dependencies and saving in S3"
  handler       = "nodeJSDependenciesLayerBuilder.handler"
  runtime       = var.runtime
  publish       = true
  memory_size   = 128
  timeout       = 900

  create_package         = false
  local_existing_package = data.archive_file.nodejs_lambda_dependencies_layer_builder.output_path

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