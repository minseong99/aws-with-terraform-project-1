variable "enable-nat-gateway" {
  description = "NAT Gateway enable"
  type        = bool
  default     = false
}

variable "enable-compute" {
  description = "EC2およびASG enable"
  type        = bool
  default     = false
}