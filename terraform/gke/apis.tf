resource "google_project_service" "enabled_apis" {
  for_each = toset(var.enabled_api_services)

  project = var.project_id
  service = each.key
  disable_dependent_services = true
  disable_on_destroy = false

}