# Create VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
}

# Create Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each      = { for subnet in var.subnets : subnet.name => subnet }
  name          = each.value.name
  region        = each.value.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = each.value.ip_cidr_range
  project       = var.project_id
  private_ip_google_access = each.value.private_ip_google_access

  # Create secondary ranges if specified
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  depends_on = [google_compute_network.vpc_network]
}

# Create Firewall Rules
resource "google_compute_firewall" "firewall_rules" {
  for_each      = { for rule in var.firewall_rules : rule.name => rule }
  name          = each.value.name
  network       = google_compute_network.vpc_network.id
  project       = var.project_id
  direction     = each.value.direction
  source_ranges = length(each.value.source_ranges) > 0 ? each.value.source_ranges : null
  destination_ranges = length(each.value.destination_ranges) > 0 ? each.value.destination_ranges : null
  source_tags   = length(each.value.source_tags) > 0 ? each.value.source_tags : null
  target_tags   = length(each.value.target_tags) > 0 ? each.value.target_tags : null
  priority      = each.value.priority

  # Add allow rules if specified
  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = length(allow.value.ports) > 0 ? allow.value.ports : null
    }
  }

  # Add deny rules if specified
  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = length(deny.value.ports) > 0 ? deny.value.ports : null
    }
  }

  depends_on = [google_compute_network.vpc_network]
}
