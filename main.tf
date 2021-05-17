data "archive_file" "nodejs_lambda_dependencies_layer_getter" {
  type        = "zip"
  source {
    content  = file("${path.module}/src/nodeJSDependenciesLayerGetter.js")
    filename = "nodeJSDependenciesLayerGetter.js"
  } 
  output_path = "nodejs_dependencies_layer_getter.zip"
}

module "nodejs_lambda_dependencies_layer_getter" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "nodejs_lambda_dependencies_layer_getter"
  description   = "Function for getting NodeJS dependencies created layer"
  handler       = "nodeJSDependenciesLayerGetter.handler"
  runtime       = var.runtime
  publish       = true
  memory_size   = 128
  timeout       = 900

  create_package         = false
  local_existing_package = data.archive_file.nodejs_lambda_dependencies_layer_getter.output_path

  attach_policy_statements = true
  policy_statements = {
    layer_builder_permissions = {
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "lambda:*",
      ]
      resources = ["*"]
      effect    = "Allow"
    }
  }

  tags = var.tags
}


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
  description   = "Function for building NodeJS dependencies and saving in a layer"
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

resource "null_resource" "layer_builder_trigger" {
  triggers = {
    builder_version = module.nodejs_lambda_dependencies_layer_builder.lambda_function_version
  }

  provisioner "local-exec" {
    command = "touch /tmp/update"
  }

  provisioner "local-exec" {
    when = destroy
    command = "touch /tmp/destroy"
  }
}

data "aws_lambda_invocation" "nodejs_layer_builder" {
  function_name = fileexists("/tmp/update") ? module.nodejs_lambda_dependencies_layer_builder.lambda_function_name : module.nodejs_lambda_dependencies_layer_getter.lambda_function_name
  input = "{}"

  depends_on = [
    null_resource.layer_builder_trigger
  ]
}

resource "null_resource" "layer_builder_untrigger" {
  triggers = {
    depends_on = null_resource.layer_builder_trigger.id
  }

  provisioner "local-exec" {
    command = fileexists("/tmp/update") ? "rm -f /tmp/update" : "echo removed"
  }

  depends_on = [
    data.aws_lambda_invocation.nodejs_layer_builder,
  ]
}