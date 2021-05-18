variable "builder" {
  description = "Which tool should be used for building the layer. [ 'lambda' | 'codebuild' ]"
  type        = string
  default     = "lambda"
}

variable "layer_name" {
  description = "Unique name for your Lambda Layer"
  type = string
}

variable "layer_description" {
  description = "Layer's description"
  type = string
  default = ""
}

variable "license_info" {
  description = "License info for your Lambda Layer. Eg, MIT or full url of a license."
  type = string
  default     = ""
}

variable "runtime" {
  description = "Your function's runtime"
  type        = string
}

variable "compatible_runtimes" {
  description = "Up to 5 runtimes this layer is compatible with"
  type        = list(string)
  default     = []
}

variable "dependencies_file" {
  description = "File containing the dependency packages"
  type = string
}

variable "s3_bucket_name" {
  description = "An S3 Bucket to store the zip file that will create the layer"
  type        = string
}

variable "s3_key_prefix" {
  description = "The final S3 key will be <s3_key_prefix> + <layer_name> + '.zip'"
  type        = string
}

variable "delete_old_versions" {
  description = "Whether to delete old layer versions while building the current one"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}