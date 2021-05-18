resource "null_resource" "layer_builder_trigger" {
  triggers = {
    builder_version = module.nodejs_lambda_dependencies_layer_builder.lambda_function_version
  }

  provisioner "local-exec" {
    command = "touch /tmp/update"
  }
}

data "aws_lambda_invocation" "nodejs_layer_builder" {
  count = fileexists("/tmp/update") ? 1 : 0
  function_name = module.nodejs_lambda_dependencies_layer_builder.lambda_function_name
  input = <<JSON
{
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
    command = fileexists("/tmp/update") ? "rm -f /tmp/update" : "echo removed"
  }

  depends_on = [
    data.aws_lambda_invocation.nodejs_layer_builder,
  ]
}