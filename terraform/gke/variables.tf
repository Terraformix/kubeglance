variable "username" {
  type = string
  default = "google"
}

variable "enabled_api_services" {
  type = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com"
  ]
}


variable "project_id" {
  type = string
  default = "kubeglance"
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "zone" {
  type = string
  default = "us-central1-a"
}

variable "service_account_key" {
  type = string
  default = "../kubeglance-gcp-sa.json"
}

# GKE Variables
variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
  default     = "kubeglance"
}

variable "cluster_region" {
  description = "The region for the GKE cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_zone" {
  description = "The zone for the GKE cluster"
  type        = string
  default     = "us-central1-a"
}

variable "enable_private_nodes" {
  description = "Whether nodes have internal IP addresses only"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Whether the master is accessible only via internal IP"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the master nodes"
  type        = string
  default     = "172.16.0.0/28"
}

variable "pods_ipv4_cidr_block" {
  description = "CIDR block for pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_ipv4_cidr_block" {
  description = "CIDR block for services"
  type        = string
  default     = "10.0.32.0/20"
}

variable "enable_network_policy" {
  description = "Enable Kubernetes NetworkPolicy"
  type        = bool
  default     = true
}

variable "master_authorized_networks" {
  description = "CIDRs authorized to access the Kubernetes master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [{
    cidr_block   = "0.0.0.0/0"
    display_name = "All"
  }]
}

variable "node_count" {
  description = "Number of nodes per zone"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes per zone for autoscaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes per zone for autoscaling"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Boot disk size for nodes in GB"
  type        = number
  default     = 25
}

variable "disk_type" {
  description = "Boot disk type for nodes"
  type        = string
  default     = "pd-standard"
}

variable "node_labels" {
  description = "Labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Network tags to apply to nodes"
  type        = list(string)
  default     = ["gke-node"]
}