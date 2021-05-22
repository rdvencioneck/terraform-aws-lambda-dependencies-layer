locals {
  update_file = "/tmp/terraform-aws-lambda-${var.layer_name}-dependencies-layer-update"
}

resource "null_resource" "layer_builder_trigger" {
  triggers = {
    builder_version = module.lambda_dependencies_layer_builder.lambda_function_version
  }

  provisioner "local-exec" {
    command = "touch ${local.update_file}"
  }
}

data "aws_lambda_invocation" "layer_builder" {
  function_name = module.lambda_dependencies_layer_builder.lambda_function_name
  input         = <<JSON
{
  %{if !fileexists(local.update_file)}"noOps": "true",%{endif}
  "layerName": "${var.layer_name}",
  "bucket": "${var.s3_bucket_name}",
  "keyPrefix": "${var.s3_key_prefix}",
  "deleteOld": "${var.delete_old_versions}"
}
JSON

  depends_on = [
    null_resource.layer_builder_trigger
  ]
}

resource "null_resource" "layer_builder_untrigger" {
  triggers = {
    depends_on = null_resource.layer_builder_trigger.id
  }

  provisioner "local-exec" {
    command = fileexists(local.update_file) ? "rm -f ${local.update_file}" : "echo removed"
  }

  depends_on = [
    data.aws_lambda_invocation.layer_builder,
  ]
}

data "aws_s3_bucket_object" "dependencies_zip" {
  bucket = var.s3_bucket_name
  key    = "${var.s3_key_prefix}${var.layer_name}.zip"

  depends_on = [
    data.aws_lambda_invocation.layer_builder,
  ]
}