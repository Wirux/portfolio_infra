variable "region" {
  description = "AWS region"
}

variable "bucket" {
  description = "Bucket variables"
  type = object({
    name = string
  })
}
