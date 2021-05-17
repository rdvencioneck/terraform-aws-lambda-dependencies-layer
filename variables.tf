variable "builder" {
  description = "Which tool should be used for building the layer. [ 'LAMBDA' | 'CODEBUILD' ]"
  type        = string
  default     = "LAMBDA"
}

variable "layer_name" {
  type = string
}

variable "runtime" {
  description = "Function's runtime."
  type        = string
}

variable "dependencies_file" {
    type = string
}

variable "s3_bucket" {
  type        = string
  default     = null
}

variable "s3_key" {
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags"
}