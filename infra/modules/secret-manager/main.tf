locals {
  resolved_secret_names = {
    jwt_signing_key   = lookup(var.secret_names, "jwt_signing_key", "jwt-signing-key")
    vapid_private_key = lookup(var.secret_names, "vapid_private_key", "vapid-private-key")
    vapid_public_key  = lookup(var.secret_names, "vapid_public_key", "vapid-public-key")
  }
}

resource "google_secret_manager_secret" "secrets" {
  for_each = local.resolved_secret_names

  project   = var.project_id
  secret_id = each.value

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "initial" {
  for_each = {
    for key, value in var.secret_initial_values : key => value
    if contains(keys(local.resolved_secret_names), key) && trim(value) != ""
  }

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value
}

resource "google_secret_manager_secret_iam_member" "function_accessor" {
  for_each = google_secret_manager_secret.secrets

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.function_service_account_email}"
}
