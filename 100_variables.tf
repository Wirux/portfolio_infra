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
variable "compute" {
  type = object({
    ami = object({
      owners = string
      filters = list(object({
        name   = string
        values = list(string)
      }))
    })
    #instance = object({
    #  server = object({
    #    instance_type = string
    #    count         = number
    #  })
    #})
  })
}
