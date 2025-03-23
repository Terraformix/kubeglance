# Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc_network.id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc_network.name
}

output "vpc_self_link" {
  description = "The self-link of the VPC"
  value       = google_compute_network.vpc_network.self_link
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = { for name, subnet in google_compute_subnetwork.subnets : name => subnet.id }
}

output "subnet_self_links" {
  description = "Map of subnet names to their self-links"
  value       = { for name, subnet in google_compute_subnetwork.subnets : name => subnet.self_link }
}

output "subnet_regions" {
  description = "Map of subnet names to their regions"
  value       = { for name, subnet in google_compute_subnetwork.subnets : name => subnet.region }
}

output "subnet_cidr_blocks" {
  description = "Map of subnet names to CIDR blocks"
  value       = { for name, subnet in google_compute_subnetwork.subnets : name => subnet.ip_cidr_range }
}