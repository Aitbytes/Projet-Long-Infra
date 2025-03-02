variable "user_emails" {
  description = "List of email addresses of the users"
  type        = list(string)
}

variable "project_id" {
  description = "ID of the project"
  type        = string
}

provider "google" {
  credentials = file("./secrets/credentials.json")
  project     = var.project_id
  region      = "europe-west1"
}

# Define a service account
resource "google_service_account" "resrc_mgr_service_account" {
  account_id   = "resrc-mgr-service-account"  # This should be unique within the project
  display_name = "Ressource Manager Service Account"
}

# Function to create IAM bindings for given roles and members
locals {
  roles = [
    "roles/compute.admin",
    "roles/container.admin",
    "roles/storage.admin",
    "roles/run.admin",
    "roles/run.invoker",
    "roles/compute.instanceAdmin.v1",
    "roles/artifactregistry.reader", # List container images
    "roles/iam.serviceAccountUser",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
  ]
}

resource "google_project_iam_member" "role_binding" {
  for_each = {
    for pair in setproduct(var.user_emails, local.roles) :
    "${pair[0]}_${pair[1]}" => {
      email = pair[0]
      role  = pair[1]
    }
  }

  project = var.project_id
  role    = each.value.role
  member  = "user:${each.value.email}"
}

# Assign roles to the service account
resource "google_project_iam_member" "service_account_role_binding" {
  for_each = toset(local.roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.resrc_mgr_service_account.email}"
}

# Granting 'Service Account User' role to user accounts for the service account
resource "google_service_account_iam_member" "service_account_user_permission" {
  for_each   = toset(var.user_emails)
  service_account_id = google_service_account.resrc_mgr_service_account.name

  role   = "roles/iam.serviceAccountUser"
  member = "user:${each.value}"
}

# Grant 'Service Account Admin' role to user accounts for managing the service account
resource "google_service_account_iam_member" "service_account_admin_permission" {
  for_each   = toset(var.user_emails)
  service_account_id = google_service_account.resrc_mgr_service_account.name

  role   = "roles/iam.serviceAccountAdmin"
  member = "user:${each.value}"
}

