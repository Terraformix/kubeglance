variable "project_id" {
  type        = string
}

variable "network_name" {
  type        = string
}

variable "subnets" {
  type = list(object({
    name          = string
    region        = string
    ip_cidr_range = string
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
    private_ip_google_access = optional(bool, false)
  }))
  default = []
}

variable "firewall_rules" {
  type = list(object({
    name          = string
    direction     = optional(string, "INGRESS")
    source_ranges = optional(list(string), [])
    destination_ranges = optional(list(string), [])
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    priority      = optional(number, 1000)
    source_tags   = optional(list(string), [])
    target_tags   = optional(list(string), [])
  }))
  default = []
}