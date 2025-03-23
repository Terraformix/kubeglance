# VPC Module - Now with additional subnets for Jenkins and GKE
module "vpc" {
  source = "../modules/gcp_vpc"

  project_id   = var.project_id
  network_name = "my-vpc-network"
  
  subnets = [
    {
      name          = "gke-subnet"
      region        = "us-central1"
      ip_cidr_range = "10.0.0.0/24"
    },
    {
      name          = "jenkins-master-subnet"
      region        = "us-central1"
      ip_cidr_range = "10.0.1.0/24"
    },
    {
      name          = "jenkins-agent-subnet"
      region        = "us-central1"
      ip_cidr_range = "10.0.2.0/24"
    }
  ]
  
  firewall_rules = [
    {
      name          = "allow-ssh-http-https"
      direction     = "INGRESS"
      source_ranges = ["0.0.0.0/0"]
      destination_ranges = []
      source_tags   = []
      target_tags   = ["allow-jenkins-ssh"]
      priority      = 1000
      allow = [
        {
          protocol = "tcp"
          ports    = ["22", "80", "443", "8080"]
        }
      ]
      deny = []
    },
    {
      name          = "allow-jenkins-agent-communication"
      direction     = "INGRESS"
      source_ranges = []
      destination_ranges = []
      source_tags   = ["jenkins-master"]
      target_tags   = ["jenkins-agent"]
      priority      = 900
      allow = [
        {
          protocol = "tcp"
          ports    = ["22", "50000"]
        }
      ]
      deny = []
    },
    {
      name              = "allow-outbound"
      direction         = "EGRESS"
      source_ranges     = []
      destination_ranges = ["0.0.0.0/0"]
      source_tags       = []
      target_tags       = []
      priority          = 1000
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
      deny = []
    }
  ]

  depends_on = [google_project_service.enabled_apis]
}

resource "google_artifact_registry_repository" "kubeglance" {
  provider      = google
  location      = var.region
  repository_id = "kubeglance"
  format        = "DOCKER"

  depends_on = [
    module.vpc
  ]
}

resource "google_container_cluster" "gke_cluster" {
  name     = var.cluster_name
  location = var.cluster_zone # Creates a zonal cluster

  deletion_protection = false
  
  network    = module.vpc.vpc_self_link
  subnetwork = module.vpc.subnet_self_links["gke-subnet"]
  
  # Use a separate node pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Configure private cluster settings if needed
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.enable_private_nodes ? var.master_ipv4_cidr_block : null
  }
  
  # Pod and service CIDR configuration
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.pods_ipv4_cidr_block
    services_ipv4_cidr_block = var.services_ipv4_cidr_block
  }
  
  # Workload identity configuration
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  # Network policy configuration
  network_policy {
    enabled  = var.enable_network_policy
    provider = var.enable_network_policy ? "CALICO" : "PROVIDER_UNSPECIFIED"
  }
  
  # Master authorized networks
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }
  
  depends_on = [
    module.vpc
  ]
}

# Create node pool for the cluster
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.cluster_zone
  cluster    = google_container_cluster.gke_cluster.name
  node_count = var.node_count
  
  # Autoscaling configuration
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
  
  # Node configuration
  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    
    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]
    
    # Labels
    labels = var.node_labels
    
    # Tags for firewall rules
    tags = var.node_tags
    
    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    # Workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  
  # Node upgrade policy
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  
  # Node upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
  
  # Ignore changes to node_count because autoscaling will manage it
  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
  
  depends_on = [
    google_container_cluster.gke_cluster
  ]
}

resource "google_compute_address" "jenkins_master" {
  name   = "jenkins-master-static-ip"
  region = var.region
  depends_on = [module.vpc]
}

resource "google_compute_instance" "jenkins_master" {
  name         = "jenkins-master"
  machine_type = "e2-small"
  zone         = var.zone
  tags         = ["allow-jenkins-ssh", "jenkins-master"]

  network_interface {
    network    = module.vpc.vpc_self_link
    subnetwork = module.vpc.subnet_self_links["jenkins-master-subnet"]

    access_config {
      nat_ip = google_compute_address.jenkins_master.address
    }
  }

  metadata = {
    ssh-keys = "${var.username}:${file("~/.ssh/id_rsa.pub")}" 
  }

  metadata_startup_script = file("${path.module}/jenkins_master_setup.sh")

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 20
    }
  }
  
  depends_on = [module.vpc]
}

resource "google_compute_address" "jenkins_slave" {
  name   = "jenkins-agent-static-ip"
  region = var.region
  depends_on = [module.vpc]
}

resource "google_compute_instance" "jenkins_slave" {
  name         = "jenkins-agent"
  machine_type = "e2-medium"
  zone         = var.zone
  tags         = ["jenkins-agent", "allow-jenkins-ssh"]

  network_interface {
    network    = module.vpc.vpc_self_link
    subnetwork = module.vpc.subnet_self_links["jenkins-agent-subnet"]

    access_config {
      nat_ip = google_compute_address.jenkins_slave.address
    }
  }

  metadata = {
    ssh-keys = "${var.username}:${file("~/.ssh/id_rsa.pub")}"
  }

  metadata_startup_script = file("${path.module}/jenkins_slave_setup.sh")

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 20
    }
  }
  
  depends_on = [module.vpc, google_compute_instance.jenkins_master]
}