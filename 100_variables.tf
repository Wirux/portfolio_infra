variable "main" {
  type = object({
    region = string
    name   = string
  })
}
variable "network" {
  type = object({
    vpc_cidr = string
    nsg = list(object({
      name = string,
      ingress = list(object({
        from_port   = number,
        to_port     = number,
        protocol    = string,
        cidr_blocks = optional(list(string))
        self        = optional(bool)
      }))
      egress = list(object({
        from_port   = number,
        to_port     = number,
        protocol    = string,
        cidr_blocks = optional(list(string))
        self        = optional(bool)
      }))
    }))
  })
}
