variable "main" {
  type = object({
    region        = string
    name          = string
    nomad_version = string

  })
}
variable "network" {
  type = object({
    vpc_cidr    = string
    subnet_cidr = string
    nsg = map(object({
      #name = string,
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
    type = map(object({
      instance_type = string
      count         = string
      nsgs          = list(string)
      device = object({
        volume_type           = string
        volume_size           = number
        delete_on_termination = string
      })
    }))
  })
}
